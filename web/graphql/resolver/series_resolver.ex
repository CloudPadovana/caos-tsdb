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

defmodule CaosTsdb.Graphql.Resolver.SeriesResolver do
  use CaosTsdb.Web, :resolver

  defp find_tags(tags_args) do
    tags_args
    |> List.wrap
    |> Enum.map(fn args -> TagResolver.find_all(args) end)
    |> List.flatten
    |> Enum.uniq_by(fn tag -> tag.id end)
  end

  defp find_tags_ids(tags_args) do
    find_tags(tags_args)
    |> Enum.map(fn tag -> tag.id end)
    |> Enum.sort
  end

  defp to_list_of_list(_list = []), do: [[],]
  defp to_list_of_list(list) do
    list
    |> Enum.map(fn item -> List.wrap(item) end)
  end

  defp base_query(args) do
    Series
    |> QueryFilter.filter(%Series{}, args, [:id, %{metric_name: [:metric, :name]}, :period])
  end

  defp query_for(args = %{tag: tag, tags: tags}) do
    or_tags_ids = find_tags_ids(tag) |> to_list_of_list

    and_tags_ids = find_tags_ids(tags) |> to_list_of_list
    targets = or_tags_ids
    |> Enum.map(fn ids ->
      ids
      |> to_list_of_list
      |> Enum.concat(and_tags_ids)
      |> List.flatten
      |> Enum.sort
      |> Enum.uniq
      |> Enum.join(",")
    end)

    series_ids = targets
    |> Enum.flat_map(fn target ->
      SeriesTag
      |> group_by([st], st.series_id)
      |> having([st], fragment("GROUP_CONCAT(? ORDER BY ? ASC SEPARATOR ',') = ?",
                st.tag_id, st.tag_id, ^target)
      )
      |> select([st], [:series_id])
      |> Repo.all()
      |> Enum.map(fn s -> s.series_id end)
    end)
    base_query(args)
    |> where([s], s.id in ^series_ids)
  end

  defp query_for(args = %{tags: _tags}) do
    args
    |> put_in([:tag], nil)
    |> query_for()
  end

  defp query_for(args = %{tag: _tag}) do
    args
    |> put_in([:tags], [])
    |> query_for()
  end

  defp query_for(args) do
    base_query(args)
  end

  def get_one(args, _) when args == %{} do
    graphql_error(:no_arguments_given)
  end

  def get_one(args, _) do
    query = query_for(args)

    try do
      case Repo.one(query) do
        nil -> graphql_error(:not_found, "Series")
        series -> {:ok, series}
      end
    rescue
      Ecto.MultipleResultsError -> graphql_error(:multiple_results)
    end
  end

  def get_all(args, _) do
    serieses = query_for(args)
    |> Repo.all

    {:ok, serieses}
  end

  def batch_by_tag(_args, tag_ids) do
    Tag
    |> where([t], t.id in ^tag_ids)
    |> join(:inner, [t], s in assoc(t, :series))
    |> preload([_, s], [series: s])
    |> Repo.all
    |> Map.new(&{&1.id, &1.series})
  end

  def batch_by_metric(_, metric_names) do
    Metric
    |> where([m], m.name in ^metric_names)
    |> join(:inner, [m], s in assoc(m, :series))
    |> preload([_, s], [series: s])
    |> Repo.all
    |> Map.new(&{&1.name, &1.series})
  end

  def create(args, _) when args == %{} do
    graphql_error(:no_arguments_given)
  end

  def create(_args = %{period: period, metric: %{name: metric_name}, tags: tags}, _) do
    changeset_args = %{period: period, metric_name: metric_name}
    tags = find_tags(tags)

    series = %Series{}
    |> Series.changeset(changeset_args)
    |> Ecto.Changeset.put_assoc(:tags, tags)
    |> Ecto.Changeset.validate_length(:tags, min: 1)

    trx = Ecto.Multi.new
    |> Ecto.Multi.insert(:series, series)

    case Repo.transaction(trx) do
      {:ok, %{series: series}} -> {:ok, series}
      {:error, _, failed_changeset, _changes_so_far} -> {:error, failed_changeset}
    end
    |> changeset_to_graphql()
  end

  def get_or_create(args, context) do
    query = query_for(args)

    try do
      case Repo.one(query) do
        nil -> create(args, context)
        series -> {:ok, series}
      end
    rescue
      Ecto.MultipleResultsError -> graphql_error(:multiple_results)
    end
  end

  def batch_by_sample(_, series_ids) do
    ids = series_ids |> Enum.uniq

    Series
    |> where([s], s.id in ^ids)
    |> Repo.all
    |> Map.new(&{&1.id, &1})
  end
end
