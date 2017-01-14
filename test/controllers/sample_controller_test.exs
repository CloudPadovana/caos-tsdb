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

defmodule CaosTsdb.SampleControllerTest do
  use CaosTsdb.ConnCase

  import CaosTsdb.DateTime.Helpers
  alias CaosTsdb.Sample
  alias CaosTsdb.Series
  alias CaosTsdb.Metric
  use Timex

  @metric %Metric{name: "a name", type: "a type"}

  @series %Series{id: 1,
                  metric_name: "a name",
                  period: 3600,
                  ttl: 500}

  @valid_attrs %{series_id: 1,
                 timestamp: Timex.now |> Timex.format!("%FT%TZ", :strftime),
                 value: 322.3}
  @sample struct(Sample, @valid_attrs)

  setup %{conn: conn} do
    conn = conn
    |> put_req_header("accept", "application/json")
    |> put_valid_token()

    {:ok, conn: conn}
  end

  test "shows chosen resource", %{conn: conn} do
    Repo.insert! @metric
    Repo.insert! @series

    Repo.insert! %{ @sample | timestamp: Timex.parse!(@sample.timestamp, "%FT%TZ", :strftime)}
    conn = get conn, sample_path(conn, :show, %{series_id: @sample.series_id})
    assert json_response(conn, 200)["data"] == [%{
      "series_id" => @sample.series_id,
      "value" => @sample.value,
      "timestamp" => @sample.timestamp}]
  end

  test "renders empty list when sample is nonexistent", %{conn: conn} do
    conn = get conn, sample_path(conn, :show, %{series_id: -1})
    assert json_response(conn, 200)["data"] == []
  end

  test "creates and renders resource when data is valid", %{conn: conn} do
    Repo.insert! @metric
    Repo.insert! @series
    conn = post conn, sample_path(conn, :create), sample: @valid_attrs
    assert json_response(conn, 201)["data"]
    assert Repo.get_by(Sample, @valid_attrs)
  end

  test "shows samples from date",  %{conn: conn}  do
    Repo.insert! @metric
    Repo.insert! @series

    t0 = "2016-08-02T05:04:29Z" |> parse_date!

    samples = 1..10 |> Enum.map(fn(x) ->
      sample = %{@sample | timestamp: t0 |> Timex.shift(hours: x),
                 value: :rand.uniform()*x}

      Repo.insert! sample

      %{"series_id" => sample.series_id,
        "value" => sample.value,
        "timestamp" => sample.timestamp |> format_date!}
    end)


    from = "2016-08-02T05:04:29Z"
    new_conn = get conn, sample_path(conn, :show, %{series_id: @sample.series_id}), from: from
    assert json_response(new_conn, 200)["data"] == samples

    from = "2016-08-02T09:00:00Z"
    new_conn = get conn, sample_path(conn, :show, %{series_id: @sample.series_id}), from: from
    assert json_response(new_conn, 200)["data"] == Enum.slice(samples, 3..10)


    from = "2016-08-02T09:00:00Z"
    to = "2016-08-02T13:00:00Z"
    new_conn = get conn, sample_path(conn, :show, %{series_id: @sample.series_id}), from: from, to: to
    assert json_response(new_conn, 200)["data"] == Enum.slice(samples, 3..6)


    from = "2016-08-03T09:00:00Z"
    new_conn = get conn, sample_path(conn, :show, %{series_id: @sample.series_id}), from: from
    assert json_response(new_conn, 200)["data"] == []

    end
end
