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

  alias CaosTsdb.Series
  alias CaosTsdb.Tag
  alias CaosTsdb.Metric

  def get_one(args, _) when args == %{} do
    graphql_error(:no_arguments_given)
  end

  def get_one(args = %{id: _id} , _) do
    try do
      case Repo.get_by(Series, args) do
        nil -> graphql_error(:not_found, "Series")
        series -> {:ok, series}
      end
    rescue
      Ecto.MultipleResultsError -> graphql_error(:multiple_results)
    end
  end

  def get_one(_args = %{period: period, metric: %{name: metric_name}, tags: tags}, _) do
    tag_ids = tags
    |> Enum.map(fn tag_args ->
      tag = Tag
      |> select([:id])
      |> Repo.get_by(tag_args)

      tag.id
    end)

    query = Series
    |> where(period: ^period)
    |> where(metric_name: ^metric_name)
    |> join(:inner, [s], t in assoc(s, :tags))
    |> where([_, t], t.id in ^tag_ids)
    |> group_by([s, _], s.id)
    |> having([s, _], count(s.id) == ^length(tag_ids))
    |> preload([_, t], [tags: t])

    try do
      case Repo.one(query) do
        nil -> graphql_error(:not_found, "Series")
        series -> {:ok, series}
      end
    rescue
      Ecto.MultipleResultsError -> graphql_error(:multiple_results)
    end
  end
  def metric_by_series(_, metric_names) do
    Metric
    |> where([m], m.name in ^metric_names)
    |> Repo.all
    |> Map.new(&{&1.name, &1})
  end

  def tags_by_series(_, series_ids) do
    Series
    |> where([s], s.id in ^series_ids)
    |> join(:inner, [s], t in assoc(s, :tags))
    |> preload([s, t], [tags: t])
    |> Repo.all
    |> Map.new(&{&1.id, &1.tags})
  end
end
