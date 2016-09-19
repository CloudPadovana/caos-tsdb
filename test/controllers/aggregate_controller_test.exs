######################################################################
#
# Filename: aggregate_controller_test.exs
# Created: 2016-09-19T10:24:36+0200
# Time-stamp: <2016-09-19T13:58:18cest>
# Author: Fabrizio Chiarello <fabrizio.chiarello@pd.infn.it>
#
# Copyright © 2016 by Fabrizio Chiarello
#
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
######################################################################

defmodule CaosApi.AggregateControllerTest do
  use CaosApi.ConnCase

  import CaosApi.DateTime.Helpers
  alias CaosApi.Sample
  alias CaosApi.Series
  alias CaosApi.Project
  alias CaosApi.Metric
  use Timex
  import CaosApi.Fixtures

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  defp avg(l) do
    Enum.sum(l)/(length(l))
  end

  defp var(l) do
    a = avg(l)
    l2 = Enum.map(l, fn(x) -> x*x end)
    avg(Enum.map(l2, fn(x) -> x - a*a end))
  end

  defp aggr(vals) do
    res = %{"avg" => avg(vals),
            "count" => Enum.count(vals),
            "min" => Enum.min(vals),
            "max" => Enum.max(vals),
            "var" => var(vals),
            "std" => :math.sqrt(var(vals)),
            "sum" => Enum.sum(vals)}
    myround(res)
  end

  defp myround(res) do
    Enum.reduce(["avg", "count", "min", "max", "var", "std", "sum"], res, fn(k, acc) ->
      Map.put(acc, k, Float.round(res[k] + 0.0, 10))
    end)
  end

  test "test1", %{conn: conn} do
    project1 = fixture(:project, 1)
    project2 = fixture(:project, 2)
    metric1 = fixture(:metric, "metric1")
    metric2 = fixture(:metric, "metric2")
    series11 = fixture(:series, project: project1, metric: metric1, period: 3600)
    series12 = fixture(:series, project: project1, metric: metric2, period: 3600)
    series21 = fixture(:series, project: project2, metric: metric1, period: 3600)
    series22 = fixture(:series, project: project2, metric: metric2, period: 3600)

    t1 = "2016-08-08T00:00:00Z" |> parse_date!
    t2 = "2016-08-09T00:00:00Z" |> parse_date!
    t3 = "2016-08-10T00:00:00Z" |> parse_date!
    t4 = "2016-08-10T03:00:00Z" |> parse_date!
    samples11 = fixture(:samples, from: t1, n: 12, series: series11)
    samples12 = fixture(:samples, from: t2, n: 12, series: series11)
    samples13 = fixture(:samples, from: t3, n: 12, series: series11)

    vals = Enum.map(samples11, fn(s) -> s.value end)
    res11 = Map.merge(aggr(vals), %{"timestamp" => t2 |> format_date!,
                                    "project_id" => "id1"})
    vals = Enum.map(samples12, fn(s) -> s.value end)
    res12 = Map.merge(aggr(vals), %{"timestamp" => t3 |> format_date!,
                                    "project_id" => "id1"})
    vals = Enum.map(samples13, fn(s) -> s.value end)
    res13 = Map.merge(aggr(Enum.slice(vals, 0..2)), %{"timestamp" => "2016-08-11T00:00:00Z",
                                                     "project_id" => "id1"})

    conn = get conn, aggregate_path(conn, :show, %{metric: "metric1",
                                                   period: 3600,
                                                   from: t1 |> format_date!,
                                                   to: t4 |> format_date!,
                                                   granularity: 60*60*24,
                                                   projects: [project1.id],
                                                  })
    data = json_response(conn, 200)["data"]
    assert myround(Enum.at(data["id1"], 0)) == res11
    assert myround(Enum.at(data["id1"], 1)) == res12
    assert myround(Enum.at(data["id1"], 2)) == res13

    samples21 = fixture(:samples, from: t1, n: 12, series: series21)
    samples22 = fixture(:samples, from: t2, n: 12, series: series21)
    samples23 = fixture(:samples, from: t3, n: 12, series: series21)

    samples21a = fixture(:samples, from: t1, n: 12, series: series22)
    samples22a = fixture(:samples, from: t2, n: 12, series: series22)
    samples23a = fixture(:samples, from: t3, n: 12, series: series22)

    vals = Enum.map(samples21, fn(s) -> s.value end)
    res21 = Map.merge(aggr(vals), %{"timestamp" => t2 |> format_date!,
                                   "project_id" => "id2"})
    vals = Enum.map(samples22, fn(s) -> s.value end)
    res22 = Map.merge(aggr(vals), %{"timestamp" => t3 |> format_date!,
                                   "project_id" => "id2"})
    vals = Enum.map(samples23, fn(s) -> s.value end)
    res23 = Map.merge(aggr(Enum.slice(vals, 0..2)), %{"timestamp" => "2016-08-11T00:00:00Z",
                                                      "project_id" => "id2"})

    conn = get conn, aggregate_path(conn, :show, %{metric: "metric1",
                                                   period: 3600,
                                                   from: t1 |> format_date!,
                                                   to: t4 |> format_date!,
                                                   granularity: 60*60*24,
                                                   projects: [project1.id, project2.id],
                                                  })
    data = json_response(conn, 200)["data"]

    assert myround(Enum.at(data["id1"], 0)) == res11
    assert myround(Enum.at(data["id1"], 1)) == res12
    assert myround(Enum.at(data["id1"], 2)) == res13
    assert myround(Enum.at(data["id2"], 0)) == res21
    assert myround(Enum.at(data["id2"], 1)) == res22
    assert myround(Enum.at(data["id2"], 2)) == res23

  end
end
