################################################################################
#
# caos-tsdb - CAOS Time-Series DB
#
# Copyright © 2016 INFN - Istituto Nazionale di Fisica Nucleare (Italy)
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

defmodule CaosTsdb.MetricController do
  use CaosTsdb.Web, :controller

  alias CaosTsdb.Metric

  def index(conn, _params) do
    metrics = Repo.all(Metric)
    render(conn, "index.json", metrics: metrics)
  end

  def create(conn, %{"metric" => metric_params}) do
    changeset = Metric.changeset(%Metric{}, metric_params)

    case Repo.insert(changeset) do
      {:ok, metric} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", metric_path(conn, :show, metric))
        |> render("show.json", metric: metric)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(CaosTsdb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def show(conn, %{"name" => name}) do
    metric = Repo.get(Metric, name)
    if metric do
      render(conn, "show.json", metric: metric)
    else
      conn
      |> put_status(:not_found)
      |> render(CaosTsdb.ErrorView, "404.json")
    end
  end

  def update(conn, %{"name" => name, "metric" => metric_params}) do
    metric = Repo.get!(Metric, name)
    changeset = Metric.changeset(metric, metric_params)

    case Repo.update(changeset) do
      {:ok, metric} ->
        render(conn, "show.json", metric: metric)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(CaosTsdb.ChangesetView, "error.json", changeset: changeset)
    end
  end
end
