################################################################################
#
# caos-tsdb - CAOS Time-Series DB
#
# Copyright © 2017, 2018 INFN - Istituto Nazionale di Fisica Nucleare (Italy)
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

defmodule CaosTsdb.Graphql.Resolver.AggregateResolver do
  use CaosTsdb.Web, :resolver

  alias CaosTsdb.Utils.Reducer

  @spec aggregate_samples(Enumerable.t, atom) :: Sample.t
  defp aggregate_samples(samples, function) do
    acc = Reducer.acc_for(function)
    reducer = Reducer.reducer_for(function)

    timestamp = samples
    |> Enum.at(0)
    |> Map.get(:timestamp)

    value = samples
    |> Enum.map(fn s -> s.value end)
    |> Enum.reduce(acc, reducer)
    |> Reducer.value_for(function)

    %Sample{timestamp: timestamp, value: value}
  end

  @spec timestamp_for_chunk(Sample.t, DateTime.t, integer) :: DateTime.t
  defp timestamp_for_chunk(sample, epoch \\ epoch(), granularity \\ 1) do
    n = Timex.diff(sample.timestamp, epoch, :seconds)
    |> Kernel./(granularity)
    |> Float.ceil()
    |> Kernel.trunc()

    epoch
    |> Timex.shift(seconds: n*granularity)
    |> Timex.to_datetime()
  end

  @spec chunk_stream(Enumerable.t, Map.t) :: Enumerable.t
  defp chunk_stream(stream, %{from: from, granularity: granularity}) do
    stream
    |> Stream.map(fn
      sample -> %{ sample | timestamp: timestamp_for_chunk(sample, from, granularity) }
    end)
    |> Stream.chunk_by(fn s -> Timex.to_unix(s.timestamp) end)
  end

  @spec aggregate_chunk(Enumerable.t, atom) :: Enumerable.t
  defp aggregate_chunk(chunk, :none) do
    chunk
  end
  defp aggregate_chunk(chunk, function) do
    [aggregate_samples(chunk, function)]
  end

  defp check_periods([], _args) do
    {:error, "No matching series"}
  end
  defp check_periods(series, _args = %{period: period}) do
    periods = series |> Enum.map(fn s -> s.period end) |> Enum.uniq

    cond do
      periods |> Enum.count != 1
        -> {:error, "Matching series have different periods"}
      periods |> List.first != period
        -> {:error, "Matching series have wrong period"}
      true -> {:ok, period}
    end
  end
  defp check_periods(series, _args = %{id: series_id}) do
    period = series |> Enum.find(fn s -> s.id == series_id end) |> Map.get(:period)
    check_periods(series, %{period: period})
  end

  defp build_stream(_args = %{series: series_args, from: from, to: to}, context) do
    with {:ok, series} <- SeriesResolver.get_all(series_args, context),
         {:ok, period} <- check_periods(series, series_args),
         where_from <- Timex.shift(from, seconds: period),
         series_ids = Enum.map(series, fn s -> s.id end) do

      stream = Sample
      |> where([s], s.series_id in ^series_ids)
      |> where([s], s.timestamp >= ^where_from)
      |> where([s], s.timestamp <= ^to)
      |> order_by([s], [asc: s.timestamp, asc: s.series_id])
      |> Repo.stream()

      {:ok, stream}
    else
      {:error, error} -> {:error, error}
    end
  end

  defp timebase_for(_args = %{fill: :none}), do: []
  defp timebase_for(_args = %{fill: :zero, from: from, to: to, granularity: granularity}) do
    Timex.Interval.new(from: from, until: to, step: [seconds: granularity],
      left_open: false, right_open: false)
      |> Enum.map(fn ts -> %Sample{timestamp: ts, value: 0} end)
  end
  defp timebase_for(_), do: []

  defp merge_fill_policy(samples, args) do
    with timebase <- timebase_for(args),
      mapped_samples <- Enum.group_by(samples, fn s -> Timex.to_unix(s.timestamp) end) do

      timebase
      |> Enum.group_by(fn s -> Timex.to_unix(s.timestamp) end)
      |> Map.merge(mapped_samples)
      |> Map.values()
      |> List.flatten()
    end
  end

  def aggregate_term(args = %{downsample: downsample_function, function: function}, context) do
    with {:ok, stream} <- build_stream(args, context) do

      Repo.transaction(fn ->
        stream
        |> chunk_stream(args)
        |> Stream.flat_map(fn chunk ->
          chunk
          |> Enum.group_by(fn s -> s.series_id end)
          |> Enum.flat_map(fn {_series_id, samples} ->
            aggregate_chunk(samples, downsample_function)
          end)
          |> aggregate_chunk(function)
        end)
        |> Enum.to_list()
        |> merge_fill_policy(args)
      end, timeout: :infinity)
    else
      {:error, error} -> {:error, error}
    end
  end

  @expression_term_name "x"

  def aggregate(args, context) do
    term_args = args
    |> Map.take([:series, :function, :downsample, :fill])
    |> put_in([:name], @expression_term_name)

    expr_args = args
    |> Map.take([:from, :to, :granularity])
    |> put_in([:terms], [term_args])
    |> put_in([:expression], @expression_term_name)

    ExpressionResolver.expression(expr_args, context)
  end
end
