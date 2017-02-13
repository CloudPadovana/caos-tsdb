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

defmodule CaosTsdb.Graphql.Resolver.MetricResolver do
  use CaosTsdb.Web, :resolver

  alias CaosTsdb.Metric

  def get_one(args, _) when args == %{} do
    graphql_error(:no_arguments_given)
  end

  def get_one(args, _) do
    case Repo.get_by(Metric, args) do
      nil -> graphql_error(:not_found, "Metric")
      metric -> {:ok, metric}
    end
  end

  def get_all(args, _) when args == %{} do
    {:ok, Metric |> Repo.all}
  end

  def get_all(args, _) do
    metrics = Metric
    |> CaosTsdb.QueryFilter.filter(%Metric{}, args, [:name, :type])
    |> Repo.all

    {:ok, metrics}
  end

  def create(args, _) when args == %{} do
    graphql_error(:no_arguments_given)
  end

  def create(args, _) do
    %Metric{}
    |> Metric.changeset(args)
    |> Repo.insert
    |> changeset_to_graphql
  end

  def get_or_create(args, context) do
    case Repo.get_by(Metric, args) do
      nil -> create(args, context)
      metric -> {:ok, metric}
    end
  end

  def update(args = %{name: name}, context) do
    case get_one(%{name: name}, context) do
      {:ok, metric} ->
        metric
        |> Metric.changeset(args)
        |> Repo.update
        |> changeset_to_graphql

      {:error, error} -> {:error, error}
    end
  end
end
