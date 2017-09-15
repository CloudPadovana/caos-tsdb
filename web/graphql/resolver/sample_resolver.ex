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

defmodule CaosTsdb.Graphql.Resolver.SampleResolver do
  use CaosTsdb.Web, :resolver

  def get_last(args, _) when args == %{} do
    graphql_error(:no_arguments_given)
  end

  def get_last(_args = %{series: series_args}, context) do
    with {:ok, series} <- SeriesResolver.get_one(series_args, context) do
      try do
        case Repo.get_by(Sample, series_id: series.id, timestamp: series.last_timestamp) do
          nil -> graphql_error(:not_found, "Sample")
          sample ->
            {:ok, %{
                series: series,
                timestamp: sample.timestamp,
                value: sample.value
             }}
        end
      rescue
        Ecto.MultipleResultsError -> graphql_error(:multiple_results)
      end
    else
      {:error, error} -> {:error, error}
    end
  end

  def get_last_value(args = %{series: _series_args}, context) do
    with {:ok, sample} <- get_last(args, context) do
      {:ok, sample.value}
    else
      {:error, error} -> {:error, error}
    end
  end

  def get_one(args, _) when args == %{} do
    graphql_error(:no_arguments_given)
  end

  def get_one(_args = %{series: series_args, timestamp: timestamp}, context) do
    with {:ok, series} <- SeriesResolver.get_one(series_args, context) do
      try do
        query = Sample
        |> where([s], s.series_id == ^series.id)
        |> where([s], s.timestamp == ^timestamp)

        case Repo.one(query) do
          nil -> graphql_error(:not_found, "Sample")
          sample -> {:ok, %{ sample | series: series }}
        end
      rescue
        Ecto.MultipleResultsError -> graphql_error(:multiple_results)
      end
    else
      {:error, error} -> {:error, error}
    end
  end

  def get_all(args, _) when args == %{} do
    graphql_error(:no_arguments_given)
  end

  def get_all(_args = %{series: series_args, from: from, to: to}, context) do
    with {:ok, series} <- SeriesResolver.get_one(series_args, context) do
      samples = Sample
      |> where([s], s.series_id == ^series.id)
      |> where([s], s.timestamp >= ^from)
      |> where([s], s.timestamp <= ^to)
      |> order_by([s], [asc: s.timestamp])
      |> Repo.all()

      {:ok, samples}
    else
      {:error, error} -> {:error, error}
    end
  end

  def batch_by_series(_args = %{timestamp: timestamp}, series_ids) do
    Sample
    |> where([s], s.series_id in ^series_ids)
    |> join(:inner, [s], series in assoc(s, :series))
    |> preload([s, series], [series: series])
    |> having([s, series], s.timestamp == ^timestamp)
    |> Repo.all
    |> Enum.group_by(&(&1.series_id))
    |> Enum.to_list
    |> Map.new(fn {series_id, samples} -> {series_id, samples |> Enum.at(0, %Sample{})} end)
  end

  def batch_by_series(_args = %{from: from, to: to}, series_ids) do
    Series
    |> where([s], s.id in ^series_ids)
    |> join(:inner, [s], samples in assoc(s, :samples))
    |> preload([s, samples], [samples: samples])
    |> having([_, samples], samples.timestamp >= ^from)
    |> having([_, samples], samples.timestamp <= ^to)
    |> Repo.all
    |> Enum.group_by(&(&1.id), &(&1.samples))
  end

  def batch_by_series(_args, series_ids) do
    series_ids
    |> Map.new(fn id -> {id, %Sample{}} end)
  end

  def batch_last_by_series(_, series_ids) do
    Sample
    |> where([s], s.series_id in ^series_ids)
    |> join(:inner, [s], series in assoc(s, :series))
    |> preload([s, series], [series: series])
    |> having([s, series], s.timestamp == series.last_timestamp)
    |> Repo.all
    |> Enum.group_by(&(&1.series_id))
    |> Enum.to_list
    |> Map.new(fn {series_id, samples} -> {series_id, samples |> Enum.at(0, %Sample{})} end)
  end

  defp foreseen_threshold(value) when is_integer(value) and value > 0, do: value
  defp foreseen_threshold(_), do: 0
  defp foreseen_threshold() do
    foreseen_threshold(Application.get_env(:caos_tsdb, ForeseenSample)[:threshold])
  end

  defp foreseen_enabled(), do: foreseen_threshold() > 0

  @spec get_overwrite_for(Sample.t, boolean) :: boolean
  defp get_overwrite_for(_sample, _overwrite = true), do: true
  defp get_overwrite_for(_sample = %Sample{timestamp: nil}, _), do: false
  defp get_overwrite_for(_sample = %Sample{updated_at: nil}, _), do: false
  defp get_overwrite_for(_sample = %Sample{timestamp: timestamp, updated_at: updated_at}, _)
    when updated_at > timestamp, do: false
  defp get_overwrite_for(_sample = %Sample{timestamp: timestamp, updated_at: updated_at}, _) do
    cond do
      not foreseen_enabled() -> false
      not Timex.before?(timestamp, Timex.now) -> true
      Timex.diff(Timex.now, timestamp, :seconds) >= foreseen_threshold() -> true
      true -> false
    end
  end

  def create(args, _) when args == %{} do
    graphql_error(:no_arguments_given)
  end

  def create(_args = %{series: series_args,
                       timestamp: timestamp,
                       value: value,
                       overwrite: overwrite
                      }, context) do
    with {:ok, series} <- SeriesResolver.get_or_create(series_args, context) do
      sample = Sample
      |> CaosTsdb.QueryFilter.filter(%Sample{}, %{series_id: series.id, timestamp: timestamp}, [:series_id, :timestamp])
      |> Repo.one

      sample = case sample do
                 nil -> %Sample{}
                 sample -> sample
               end

      changeset_args = %{series_id: series.id,
                         timestamp: timestamp,
                         value: value,
                         overwrite: get_overwrite_for(sample, overwrite)}

      sample = sample
      |> Sample.changeset(changeset_args)

      trx = Ecto.Multi.new
      |> Ecto.Multi.insert_or_update(:sample, sample)
      |> Ecto.Multi.run(:last_timestamp, fn
        _changes_so_far -> update_last_timestamp(series.id)
      end)

      case Repo.transaction(trx) do
        {:ok, %{sample: sample}} -> {:ok, sample}
        {:error, _, failed_changeset, _changes_so_far} -> {:error, failed_changeset}
      end
    end
    |> changeset_to_graphql()
  end

  defp update_last_timestamp(series_id) do
    last_timestamp = (from s in Sample, where: s.series_id == ^series_id)
    |> Repo.aggregate(:max, :timestamp)

    series = Repo.get_by!(Series, id: series_id)
    changeset = Series.changeset(series, %{"last_timestamp" => last_timestamp})

    Repo.update(changeset)
  end
end
