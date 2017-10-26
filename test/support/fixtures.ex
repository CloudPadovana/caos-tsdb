################################################################################
#
# caos-tsdb - CAOS Time-Series DB
#
# Copyright © 2016, 2017 INFN - Istituto Nazionale di Fisica Nucleare (Italy)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#
# Author: Fabrizio Chiarello <fabrizio.chiarello@pd.infn.it>
#
################################################################################

defmodule CaosTsdb.Fixtures do
  import Ecto
  import Ecto.Query

  alias CaosTsdb.Repo
  alias CaosTsdb.Tag
  alias CaosTsdb.TagMetadata
  alias CaosTsdb.Sample
  alias CaosTsdb.Series
  alias CaosTsdb.SeriesTag
  alias CaosTsdb.Metric
  use Timex
  import CaosTsdb.DateTime.Helpers
  alias CaosTsdb.QueryFilter

  def fixture(_, assoc \\ [])

  def fixture(:timestamp, _assoc) do
    Timex.now
    |> format_date!
    |> parse_date!
  end

  def fixture(:value, _assoc) do
    :rand.uniform()
  end

  def fixture(:token, assoc) do
    username = assoc[:username] || "some_user"
    claims = assoc[:claims] || %{}

    {:ok, jwt, _} = Guardian.encode_and_sign(username, :access, claims)
    jwt
  end

  def fixture(:tag, assoc) do
    Tag.changeset(%Tag{}, %{
      key: assoc[:key] || "tag1",
      value: assoc[:value] || "value1",
      extra: %{"data key1" => "data value1"}
    })
    |> Repo.insert!
  end

  def fixture(:tag_metadata, assoc) do
    tag = assoc[:tag] || fixture(:tag)
    t0 = assoc[:from] || epoch()
    granularity = assoc[:granularity] || 3600
    n = assoc[:repeat] || 1

    _metas = Range.new(0, n-1) |> Enum.map(fn(x) ->
      timestamp = t0 |> Timex.shift(seconds: x*granularity)

      metadata = %TagMetadata{
        tag_id: tag.id,
        timestamp: timestamp,
        metadata: "metadata#{x}"}
      Repo.insert! metadata
    end)
  end

  def fixture(:tags, assoc) do
    [fixture(:tag),
     fixture(:tag,
       key: "tag2",
       value: "value_2",
       extra: %{"data key1" => "data value1",
                "data key2" => "data value2"})]
  end

  def fixture(:metric, assoc) do
    Metric.changeset(%Metric{}, %{
      name: assoc[:name] || "metric1",
      type: assoc[:type] || "type1"
    })
    |> Repo.insert!
    |> Repo.preload(:series)
  end

  def fixture(:series, assoc) do
    metric = assoc[:metric] || fixture(:metric)
    period = assoc[:period] || 3600
    tags = assoc[:tags] || [fixture(:tag)]

    tags_ids = tags |> Enum.map(fn tag -> tag.id end) |> Enum.sort |> Enum.uniq
    target = tags_ids |> Enum.join(",")

    series_ids = SeriesTag
    |> group_by([st], st.series_id)
    |> having([st], fragment("GROUP_CONCAT(? ORDER BY ? ASC SEPARATOR ',') = ?",
              st.tag_id, st.tag_id, ^target)
    )
    |> select([st], [:series_id])
    |> Repo.all()
    |> Enum.map(fn s -> s.series_id end)

    query = Series
    |> QueryFilter.filter(%Series{}, %{period: period, metric: %{name: metric.name}, tags: tags}, [:id, %{metric_name: [:metric, :name]}, :period])
    |> where([s], s.id in ^series_ids)

    case Repo.one(query) do
      nil -> %Series{}
      |> Series.changeset(%{metric_name: metric.name, period: period })
      |> Ecto.Changeset.put_assoc(:tags, tags)
      |> Ecto.Changeset.validate_length(:tags, min: 1)
      |> Repo.insert!

      series -> {:ok, series}
    end
  end

  def fixture(:sample, assoc) do
    series = assoc[:series] || fixture(:series)
    t0 = assoc[:timestamp] || epoch()
    value = assoc[:value] || fixture(:value)

    Repo.insert! %Sample{series_id: series.id,
                         timestamp: t0,
                         value: value}
  end

  def fixture(:samples, assoc) do
    series = assoc[:series] || fixture(:series)
    t0 = assoc[:from] || epoch()
    n = assoc[:repeat] || 1
    n0 = assoc[:start_value] || 0
    value_type = assoc[:values] || :rand
    time_shift = assoc[:time_shift] || series.period

    _samples = Range.new(n0, n-1) |> Enum.map(fn(x) ->
      value = case value_type do
                :rand -> :rand.uniform()
                :linear -> x+1.0
              end
      sample = Sample.changeset(%Sample{}, %{
        series_id: series.id,
        timestamp: t0 |> Timex.shift(seconds: x*time_shift),
        value: value})
      |> Repo.insert!
    end)
  end

  @spec timestamp_for_chunk(Sample.t, DateTime.t, integer) :: DateTime.t
  defp timestamp_for_chunk(sample, epoch \\ epoch(), granularity \\ 1) do
    n = Timex.diff(sample.timestamp, epoch, :seconds)
    |> Kernel./(granularity)
    |> Float.ceil()
    |> Kernel.trunc()

    Timex.shift(epoch, seconds: n*granularity)
    |> Timex.to_datetime()
  end

  # emulate AVG
  defp avg(l) when is_list(l) do
    Enum.sum(l)/(length(l))
  end

  # emulate VAR
  defp var(l) when is_list(l) do
    a = avg(l)
    l2 = Enum.map(l, fn(x) -> x*x end)
    avg(Enum.map(l2, fn(x) -> x - a*a end))
  end

  defp aggr_function(function, values) do
    case function do
      "AVG" -> avg(values)
      "COUNT" -> Enum.count(values)
      "MIN" -> Enum.min(values)
      "MAX" -> Enum.max(values)
      "VAR" -> var(values)
      "STD" -> :math.sqrt(var(values))
      "SUM" -> Enum.sum(values)
    end
  end

  # calculate fixture aggregation
  defp aggr([], :count) do 0 end
  defp aggr([], function) do nil end
  defp aggr(values, function) when is_number(values) do
    aggr([values], function)
  end
  defp aggr(values, function) when is_list(values) do
    aggr_function(function, values)
  end

  def fixture(:aggregate, samples_groups, assoc) do
    from = case assoc[:from] do
             nil -> epoch()
             f -> f |> parse_date!
           end
    to = case assoc[:to] do
           nil -> Timex.now
           t -> t |> parse_date!
         end
    period = case assoc[:series][:period] do
               nil ->
                 samples_groups
                 |> List.flatten
                 |> Enum.map(fn s -> s.series_id end)
                 |> Enum.uniq
                 |> Enum.map(fn id -> Repo.get(Series, id) end)
                 |> Enum.map(fn s -> s.period end)
                 |> Enum.uniq
                 |> Enum.at(0)
               n -> n
             end

    granularity = assoc[:granularity] || Timex.diff(to, from, :seconds)
    function = assoc[:function]
    downsample = assoc[:downsample] || "NONE"

    where_from = Timex.shift(from, seconds: period)

    samples_groups
    |> Enum.concat()
    |> Enum.filter(fn s ->
      (Timex.compare(s.timestamp, to) < 1) && (Timex.compare(s.timestamp, where_from) > -1)
    end)
    |> Enum.map(fn sample
      -> %{ sample | timestamp: timestamp_for_chunk(sample, from, granularity) }
    end)
    |> Enum.group_by(fn s -> s.series_id end)
    |> Enum.flat_map(fn {series_id, samples} ->
      if downsample == "NONE" do
        samples
      else
        samples
        |> Enum.group_by(fn s -> s.timestamp end)
        |> Enum.flat_map(fn {timestamp, samples} ->
          [%Sample{
            timestamp: timestamp,
            value: samples |> Enum.map(fn s -> s.value end) |> aggr(downsample)}]
        end)
      end
    end)
    |> Enum.group_by(fn s -> s.timestamp end)
    |> Enum.flat_map(fn {timestamp, samples} ->
      if function == "NONE" do
        samples
      else
        [%Sample{
          timestamp: timestamp,
          value: samples |> Enum.map(fn s -> s.value end) |> aggr(function)}]
      end
    end)
    |> Enum.sort_by(fn s -> s.timestamp end, &(Timex.compare(&2, &1) > -1))
  end

  def fixture(:expression, terms_samples_groups, assoc) do
    from = case assoc[:from] do
             nil -> epoch()
             f -> f |> parse_date!
           end
    to = case assoc[:to] do
           nil -> Timex.now
           t -> t |> parse_date!
         end
    granularity = assoc[:granularity] || Timex.diff(to, from, :seconds)
    expression = assoc[:expression]

    samples_map = terms_samples_groups
    |> Enum.map(fn {name, samples_group} ->
      aggr_params = assoc
      |> Map.take([:from, :to, :granularity])
      |> Map.merge(Enum.find(assoc[:terms], fn t -> t.name == name end))

      {name, fixture(:aggregate, samples_group, aggr_params)}
    end)

    real_from = samples_map
    |> Enum.map(fn {_, samples} ->
      samples
      |> Enum.map(fn s -> s.timestamp end)
      |> Enum.min_by(&Timex.to_unix/1)
    end)
    |> Enum.concat([from])
    |> Enum.max_by(&Timex.to_unix/1)

    real_to = samples_map
    |> Enum.map(fn {_, samples} ->
      samples
      |> Enum.map(fn s -> s.timestamp end)
      |> Enum.max_by(&Timex.to_unix/1)
    end)
    |> Enum.concat([to])
    |> Enum.min_by(&Timex.to_unix/1)

    Timex.Interval.new(from: real_from, until: real_to, step: [seconds: granularity], right_open: false, left_open: false)
    |> Enum.map(&Timex.to_datetime/1)
    |> Enum.map(fn ts ->
      vars = samples_map
      |> Enum.map(fn {name, samples} ->
        sample = Enum.filter(samples, fn s -> s.timestamp == ts end)

        if length(sample) != 1 do raise "Samples Count Error "end

        {name, Map.get(List.first(sample), :value)}
      end)
      |> Map.new()

      {:ok, value} = Abacus.eval(expression, vars)

      %Sample{timestamp: ts, value: value}
    end)
  end
end
