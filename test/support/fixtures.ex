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
  alias CaosTsdb.Repo
  alias CaosTsdb.Tag
  alias CaosTsdb.TagMetadata
  alias CaosTsdb.Sample
  alias CaosTsdb.Series
  alias CaosTsdb.Metric
  use Timex
  import CaosTsdb.DateTime.Helpers

  def fixture(_, assoc \\ [])

  def fixture(:token, assoc) do
    username = assoc[:username] || "some_user"
    claims = assoc[:claims] || %{}

    {:ok, jwt, _} = Guardian.encode_and_sign(username, :access, claims)
    jwt
  end

  def fixture(:tag, assoc) do
    Repo.insert! %Tag{
      key: assoc[:key] || "tag1",
      value: assoc[:value] || "value1",
      extra: %{"data key1" => "data value1"}
    }
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
       value: "value 2",
       extra: %{"data key1" => "data value1",
                "data key2" => "data value2"})]
  end

  def fixture(:metric, assoc) do
    Repo.insert! %Metric{
      name: assoc[:name] || "metric1",
      type: assoc[:type] || "type1"
    }
    |> Repo.preload(:series)
  end

  def fixture(:series, assoc) do
    metric = assoc[:metric] || fixture(:metric)
    period = assoc[:period] || 3600
    tags = assoc[:tags] || [fixture(:tag)]

    _series = %Series{
      metric_name: metric.name,
      period: period
    }
    |> Repo.insert!
    |> Repo.preload(:tags)
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:tags, tags)
    |> Repo.update!
  end

  def fixture(:sample, assoc) do
    series = assoc[:series] || fixture(:series)
    t0 = assoc[:timestamp] || epoch()
    value = assoc[:value] || :rand.uniform()

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

    _samples = Range.new(n0, n-1) |> Enum.map(fn(x) ->
      value = case value_type do
                :rand -> :rand.uniform()
                :linear -> x+1.0
              end
      sample = %Sample{series_id: series.id,
                       timestamp: t0 |> Timex.shift(seconds: x*series.period),
                       value: value}
      Repo.insert! sample
    end)
  end

  @spec timestamp_for_chunk(Sample.t, DateTime.t, integer) :: DateTime.t
  defp timestamp_for_chunk(sample, epoch \\ epoch(), granularity \\ 1) do
    n = Timex.diff(sample.timestamp, epoch, :seconds)
    |> Kernel./(granularity)
    |> Float.ceil()
    |> Kernel.trunc()

    Timex.shift(epoch, seconds: n*granularity)
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
end
