################################################################################
#
# caos-tsdb - CAOS Time-Series DB
#
# Copyright © 2017 INFN - Istituto Nazionale di Fisica Nucleare (Italy)
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

  @spec aggregate_values(Enumerable.t, atom) :: number
  defp aggregate_values([], :avg) do 0 end
  defp aggregate_values(values, :avg) do
    Enum.reduce(values, {0, 0}, fn
      v, {sum, count} -> {sum + v, count + 1}
    end)
    |> (fn
      {sum, count} -> sum / count
    end).()
  end
  defp aggregate_values(values, :count) do Enum.count(values) end
  defp aggregate_values(values, :min) do Enum.min(values) end
  defp aggregate_values(values, :max) do Enum.max(values) end
  defp aggregate_values(values, :sum) do Enum.sum(values) end
  defp aggregate_values(values, :var) do
    # Welford algorithm
    Enum.reduce(values, {0, 0, 0}, fn
      v, {n, mean, M2} ->
        new_n = n + 1
        delta = v - mean
        new_mean = mean + (delta / new_n)
        delta2 = v - new_mean
        new_M2 = M2 + (delta*delta2)

        {new_n, new_mean, new_M2}
    end)
    |> (fn
      {n, _mean, _M2} when n < 2 -> 0
      {n, _mean, M2} -> M2 / (n-1)
    end).()
  end
  defp aggregate_values(values, :std) do
    aggregate_values(values, :var) |> :math.sqrt
  end

  @spec aggregate_samples(Enumerable.t, atom) :: Sample.t
  defp aggregate_samples(samples, function) do
    %Sample{
      timestamp: samples |> Enum.at(0) |> Map.get(:timestamp),
      value: samples |> Enum.map(fn s -> s.value end) |> aggregate_values(function)
    }
  end

  @spec timestamp_for_chunk(Sample.t, DateTime.t, integer) :: DateTime.t
  defp timestamp_for_chunk(sample, epoch \\ epoch(), granularity \\ 1) do
    n = Timex.diff(sample.timestamp, epoch, :seconds)
    |> Kernel./(granularity)
    |> Float.ceil()
    |> Kernel.trunc()

    Timex.shift(epoch, seconds: n*granularity)
  end

  @spec chunk_stream(Enumerable.t, Map.t) :: Enumerable.t
  defp chunk_stream(stream, %{from: from, granularity: granularity}) do
    stream
    |> Stream.map(fn
      sample -> %{ sample | timestamp: timestamp_for_chunk(sample, from, granularity) }
    end)
    |> Stream.chunk_by(fn s -> s.timestamp end)
  end

  @spec downsample_stream(Enumerable.t, Map.t) :: Enumerable.t
  defp downsample_stream(stream, %{downsample: :none}) do
    stream
  end
  defp downsample_stream(stream, %{downsample: function}) do
    stream
    |> Stream.map(fn chunk ->
      chunk
      |> Enum.chunk_by(fn s -> s.series_id end)
      |> Enum.map(&aggregate_samples(&1, function))
    end)
  end

  @spec aggregate_stream(Enumerable.t, Map.t) :: Enumerable.t
  defp aggregate_stream(stream, %{function: :none}) do
    stream
  end
  defp aggregate_stream(stream, %{function: function}) do
    stream
    |> Stream.map(&aggregate_samples(&1, function))
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

  def aggregate(args = %{series: series_args, from: from, to: to}, context) do
    with {:ok, series} <- SeriesResolver.get_all(series_args, context),
         {:ok, period} <- check_periods(series, series_args) do

      series_ids = series |> Enum.map(fn s -> s.id end)
      where_from = from |> Timex.shift(seconds: period)

      stream = Sample
      |> where([s], s.series_id in ^series_ids)
      |> where([s], s.timestamp >= ^where_from)
      |> where([s], s.timestamp <= ^to)
      |> order_by([s], [asc: s.timestamp, asc: s.series_id])
      |> Repo.stream()

      Repo.transaction(fn ->
        stream
        |> chunk_stream(args)
        |> downsample_stream(args)
        |> aggregate_stream(args)
        |> Enum.to_list()
      end)
    else
      {:error, error} -> {:error, error}
    end
  end
end
