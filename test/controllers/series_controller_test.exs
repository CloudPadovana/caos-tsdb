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

defmodule CaosTsdb.SeriesControllerTest do
  use CaosTsdb.ConnCase

  import CaosTsdb.DateTime.Helpers

  alias CaosTsdb.Series
  alias CaosTsdb.Project
  alias CaosTsdb.Metric
  @project %Project{id: "an id", name: "a name"}
  @metric %Metric{name: "a name", type: "a type"}

  @valid_attrs %{project_id: @project.id,
                 metric_name: @metric.name,
                 tags: [],
                 period: 3600,
                 ttl: 500}
  @series struct(Series, @valid_attrs)

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
    {:ok, conn: put_valid_token(conn)}
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, series_path(conn, :index)
    assert json_response(conn, 200)["data"] == []
  end

  test "lists all entries on index with params", %{conn: conn} do
    project = fixture(:project)
    metric = fixture(:metric)
    series = fixture(:series, project: project, metric: metric, period: 3600)
    project2 = fixture(:project, id: "id2")
    series2 = fixture(:series, project: project2, metric: metric, period: 3600)

    conn = get conn, series_path(conn, :index), project_id: project.id
    assert json_response(conn, 200)["data"] == [
      %{"id" => series.id,
        "tags" => [],
        "project_id" => series.project_id,
        "metric_name" => series.metric_name,
        "period" => series.period,
        "ttl" => series.ttl,
        "last_timestamp"=> series.last_timestamp}]
  end

  test "shows chosen resource", %{conn: conn} do
    series = fixture(:series)

    conn = get conn, series_path(conn, :show, series)
    assert json_response(conn, 200)["data"] ==
      %{"id" => series.id,
        "tags" => [],
        "project_id" => series.project_id,
        "metric_name" => series.metric_name,
        "period" => series.period,
        "ttl" => series.ttl,
        "last_timestamp"=> series.last_timestamp}
  end

  describe "tags support:" do
    test "shows tags of chosen resource", %{conn: conn} do
      tags = fixture(:tags)
      _tag3 = fixture(:tag, key: "another tag", value: "a value", extra: %{key: " another value"})
      series = fixture(:series, tags: tags)

      conn = get conn, series_path(conn, :show, series)
      assert json_response(conn, 200)["data"]["tags"] ==
        tags |> Enum.map(fn (t) -> %{"id" => t.id,
                                     "key" => t.key,
                                     "value" => t.value,
                                     "extra" => t.extra} end)
    end

    test "add tags to chosen resource", %{conn: conn} do
      tags = fixture(:tags)
      series = fixture(:series)

      tag = fixture(:tag,
        key: "a tag",
        value: "a value",
        extra: %{key: " another value"})

      conn1 = get conn, series_path(conn, :show, series)
      assert json_response(conn1, 200)["data"]["tags"] == []

      conn2 = put conn, series_path(conn, :update, series), tag: %{"id" => tag.id}
      assert json_response(conn2, 200)["data"]["id"] == series.id

      conn3 = get conn, series_path(conn, :show, series)
      assert json_response(conn3, 200)["data"]["tags"] ==
        [tag] |> Enum.map(fn (t) -> %{"id" => t.id,
                                      "key" => t.key,
                                      "value" => t.value,
                                      "extra" => t.extra} end)
      tag2 = fixture(:tag,
        key: "a tag2",
        value: "a value2",
        extra: %{key: " another value2"})

      conn4 = put conn, series_path(conn, :update, series), tag: %{"id" => tag2.id}
      assert json_response(conn4, 200)["data"]["id"] == series.id

      conn5 = get conn, series_path(conn, :show, series)
      assert json_response(conn5, 200)["data"]["tags"] ==
        [tag, tag2] |> Enum.map(fn (t) -> %{"id" => t.id,
                                            "key" => t.key,
                                            "value" => t.value,
                                            "extra" => t.extra} end)

    end
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    conn = get conn, series_path(conn, :show, -1)
    assert json_response(conn, 404)["errors"] != %{}
  end

  test "creates and renders resource when data is valid", %{conn: conn} do
    Repo.insert! @project
    Repo.insert! @metric

    conn = post conn, series_path(conn, :create), series: @valid_attrs
    id = json_response(conn, 201)["data"]["id"]
    assert Repo.get_by(Series, id: id)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    Repo.insert! @project
    Repo.insert! @metric

    conn = post conn, series_path(conn, :create), series: %{@valid_attrs | project_id: "another"}
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "updates and renders chosen resource when data is valid", %{conn: conn} do
    Repo.insert! @project
    Repo.insert! @metric
    series = Repo.insert! @series

    conn = put conn, series_path(conn, :update, series), series: %{ttl: 3}
    assert json_response(conn, 200)["data"]["id"]
    assert Repo.get_by(Series, %{ttl: 3})
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    Repo.insert! @project
    Repo.insert! @metric
    series = Repo.insert! @series

    conn = put conn, series_path(conn, :update, series), series: %{ttl: "a string"}
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "grid to now", %{conn: conn} do
    project = fixture(:project)
    metric = fixture(:metric)
    series = fixture(:series, project: project, metric: metric, period: 3600)

    from = "2016-08-02T05:04:29Z"
    to = Timex.now |> format_date!

    grid = Timex.Interval.new(from: "2016-08-02T05:00:00Z" |> parse_date!,
      until: to |> parse_date!,
      step: [seconds: 3600])
      |> Enum.map(fn(x) -> format_date!(x) end)

    conn = get conn, series_grid_path(conn, :grid, series), from: from
    assert json_response(conn, 200)["data"]["grid"] == grid
  end

  test "grid from the future", %{conn: conn} do
    project = fixture(:project)
    metric = fixture(:metric)
    series = fixture(:series, project: project, metric: metric, period: 3600)

    from = Timex.now |> Timex.shift(days: 2, hours: 3) |> format_date!

    conn = get conn, series_grid_path(conn, :grid, series), from: from
    assert json_response(conn, 200)["data"]["grid"] == []
  end

end
