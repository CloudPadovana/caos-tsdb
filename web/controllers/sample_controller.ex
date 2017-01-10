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

defmodule CaosTsdb.SampleController do
  use CaosTsdb.Web, :controller

  alias CaosTsdb.Sample
  alias CaosTsdb.Series

  plug :scrub_datetime, "timestamp"
  plug :scrub_datetime, "from" when action in [:show]
  plug :scrub_datetime, "to" when action in [:show]

  def show(conn, params = %{"series_id" => _series_id, "timestamp" => _timestamp}) do
    sample = Sample
    |> CaosTsdb.QueryFilter.filter(%Sample{}, params, [:series_id, :timestamp])
    |> Repo.one

    render(conn, "show.json", sample: sample)
  end

  def show(conn, params = %{"series_id" => series_id, "from" => from}) do
    to = Map.get(params, "to", Timex.now)

    query = (from s in Sample,
      where: s.series_id == ^series_id
      and s.timestamp >= ^from
      and s.timestamp <= ^to)

    samples = query |> Repo.all
    render(conn, "show.json", samples: samples)
  end

  def show(conn, params = %{"series_id" => _series_id}) do
    samples = Sample
    |> CaosTsdb.QueryFilter.filter(%Sample{}, params, :series_id)
    |> Repo.all

    render(conn, "show.json", samples: samples)
  end

  def create(conn, %{"sample" => sample_params}) do
    sample = Sample
    |> CaosTsdb.QueryFilter.filter(%Sample{}, sample_params, [:series_id, :timestamp])
    |> Repo.one

    changeset = case sample do
                  nil -> Sample.changeset(%Sample{}, sample_params)
                  sample -> Sample.changeset(sample, sample_params)
                end

    result = case sample do
               nil -> Repo.insert(changeset) |> Tuple.append(:created)
               _ -> Repo.update(changeset) |> Tuple.append(:ok)
             end

    with {:ok, sample, status} <- result,
         {:ok, _} <- update_last_timestamp(sample.series_id) do

      conn
      |> put_status(status)
      |> put_resp_header("location", sample_path(conn, :show, %{"series_id" => sample.series_id, "timestamp" => sample.timestamp |> format_date!}))
      |> render("show.json", sample: sample)
    else
      {:error, changeset, _} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(CaosTsdb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  defp update_last_timestamp(series_id) do
    last_timestamp = (from s in Sample, where: s.series_id == ^series_id)
    |> Repo.aggregate(:max, :timestamp)

    series = Repo.get_by!(Series, id: series_id)
    changeset = Series.changeset(series, %{"last_timestamp" => last_timestamp})

    Repo.update(changeset)
  end
end
