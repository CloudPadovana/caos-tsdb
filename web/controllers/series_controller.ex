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

defmodule CaosTsdb.SeriesController do
  use CaosTsdb.Web, :controller

  alias CaosTsdb.Series
  alias CaosTsdb.Tag

  plug :scrub_datetime, "from" when action in [:grid]

  def index(conn, params) do
    series = Series
    |> CaosTsdb.QueryFilter.filter(%Series{}, params, [:id, :project_id, :metric_name, :period])
    |> Repo.all
    |> Repo.preload(:tags)

    render(conn, "index.json", series: series)
  end

  def create(conn, %{"series" => series_params}) do
    changeset = Series.changeset(%Series{}, series_params)

    case Repo.insert(changeset) do
      {:ok, series} ->
        series = series |> Repo.preload(:tags)

        conn
        |> put_status(:created)
        |> put_resp_header("location", series_path(conn, :show, series))
        |> render("show.json", series: series)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(CaosTsdb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    series = Repo.get_by(Series, id: id)
    if series do
      series = series |> Repo.preload(:tags)
      render(conn, "show.json", series: series)
    else
      conn
      |> put_status(:not_found)
      |> render(CaosTsdb.ErrorView, "404.json")
    end
  end

  def update(conn, %{"id" => id, "series" => series_params}) do
    series = Repo.get_by!(Series, id: id)
    |> Repo.preload(:tags)

    changeset = Series.changeset(series, series_params)
    case Repo.update(changeset) do
      {:ok, series} ->
        render(conn, "show.json", series: series)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(CaosTsdb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def update(conn, %{"id" => id, "tag" => _tag_params = %{"id" => tag_id}}) do
    series = Repo.get_by!(Series, id: id)
    |> Repo.preload(:tags)

    tag = Tag |> Repo.get_by!(id: tag_id)
    tags = series.tags ++ [tag]

    changeset = series
    |> Ecto.Changeset.change
    |> Ecto.Changeset.put_assoc(:tags, tags)
    case Repo.update(changeset) do
      {:ok, series} ->
        render(conn, "show.json", series: series)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(CaosTsdb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def grid(conn, %{"series_id" => id, "from" => start_date}) do
    series = Repo.get_by!(Series, id: id)
    period = series.period
    _last_timestamp = series.last_timestamp

    to = Timex.now

    d = Timex.diff(start_date, epoch, :seconds)
    n = trunc(d / period)

    from = epoch
    |> Timex.shift(seconds: n*period)

    grid = Timex.Interval.new(from: from, until: to, step: [seconds: period])
    |> Enum.map(fn(x) -> format_date!(x) end)

    render(conn, "grid.json", grid: grid)
  end
end
