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

defmodule CaosTsdb.AggregateControllerTest do
  use CaosTsdb.ConnCase

  import CaosTsdb.DateTime.Helpers
  alias CaosTsdb.Sample
  alias CaosTsdb.Series
  alias CaosTsdb.Project
  alias CaosTsdb.Metric
  use Timex

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
    {:ok, conn: put_valid_token(conn)}
  end

  # emulate AVG
  defp avg(l) when is_list(l) do
    Enum.sum(l)/(length(l))
  end

  # emulate VAR
  defp var(l) when is_list(l) do
    a = avg(l)
    l2 = Enum.map(l, fn(x) -> x*x end)
    avg(Enum.map(l2, fn(x) -> x - a*a end))
  end

  # round data to 10 decimal digits in order to match calculations by SQL
  defp myround(map) when is_list(map) do
    map |> Enum.map(fn(x) -> myround(x) end)
  end
  defp myround(map) do
    Enum.reduce(["avg", "count", "min", "max", "var", "std", "sum"], map, fn(k, acc) ->
      Map.put(acc, k, Float.round(map[k] + 0.0, 10))
    end)
  end

  # calculate fixture aggregation
  defp aggr(values) when is_number(values) do
    aggr([values])
  end
  defp aggr(values) when is_list(values) do
    map = %{"avg" => avg(values),
            "count" => Enum.count(values),
            "min" => Enum.min(values),
            "max" => Enum.max(values),
            "var" => var(values),
            "std" => :math.sqrt(var(values)),
            "sum" => Enum.sum(values)}
    myround(map)
  end

  test "daily aggregation with from", %{conn: conn} do
    project1 = fixture(:project)
    metric1 = fixture(:metric)
    series11 = fixture(:series, project: project1, metric: metric1, period: 3600)

    t0 = "2016-08-08T22:00:00Z" |> parse_date!
    t1 = "2016-08-09T22:00:00Z" |> parse_date!

    samples11h1 = fixture(:samples, from: t0, repeat: 30, series: series11)
    values = Enum.map(samples11h1 |> Enum.slice(1..24), fn(s) -> s.value end)
    aggregates11h11 = Map.merge(aggr(values), %{"timestamp" => t1 |> format_date!,
                                                "from" => t0 |> format_date!,
                                                "to" => t1 |> format_date!,
                                                "granularity" => 60*60*24})

    conn = get conn, aggregate_path(conn, :show, %{metric: "metric1",
                                                   period: 3600,
                                                   from: t0 |> format_date!,
                                                   granularity: 60*60*24,
                                                   projects: [project1.id],
                                                  })
    data = json_response(conn, 200)["data"]
    assert myround(Enum.at(data["id1"], 0)) == aggregates11h11
  end

  test "daily aggregation", %{conn: conn} do
    project1 = fixture(:project)
    metric1 = fixture(:metric)
    series11 = fixture(:series, project: project1, metric: metric1, period: 3600)

    t0 = "2016-08-08T22:00:00Z" |> parse_date!
    t1 = "2016-08-09T22:00:00Z" |> parse_date!

    samples11h1 = fixture(:samples, from: t0, repeat: 24, series: series11)

    t1a0 = "2016-08-08T00:00:00Z" |> parse_date!
    t1a = "2016-08-09T00:00:00Z" |> parse_date!
    values = Enum.map(samples11h1 |> Enum.slice(0..2), fn(s) -> s.value end)
    aggregates11h11 = Map.merge(aggr(values), %{"timestamp" => t1a |> format_date!,
                                                "from" => t1a0 |> format_date!,
                                                "to" => t1a |> format_date!,
                                                "granularity" => 60*60*24})

    t2a0 = "2016-08-09T00:00:00Z" |> parse_date!
    t2a = "2016-08-10T00:00:00Z" |> parse_date!
    values = Enum.map(samples11h1 |> Enum.slice(3..26), fn(s) -> s.value end)
    aggregates11h12 = Map.merge(aggr(values), %{"timestamp" => t2a |> format_date!,
                                                "from" => t2a0 |> format_date!,
                                                "to" => t2a |> format_date!,
                                                "granularity" => 60*60*24})

    conn = get conn, aggregate_path(conn, :show, %{metric: "metric1",
                                                   period: 3600,
                                                   granularity: 60*60*24,
                                                   projects: [project1.id],
                                                  })
    data = json_response(conn, 200)["data"]
    assert myround(Enum.at(data["id1"], 0)) == aggregates11h11
    assert myround(Enum.at(data["id1"], 1)) == aggregates11h12
  end

  test "daily aggregation with outside data", %{conn: conn} do
    project1 = fixture(:project)
    metric1 = fixture(:metric)
    series11 = fixture(:series, project: project1, metric: metric1, period: 3600)

    t0 = "2016-08-08T22:00:00Z" |> parse_date!
    t1 = "2016-08-09T22:00:00Z" |> parse_date!

    samples11h1 = fixture(:samples, from: t0, repeat: 36, series: series11)

    t1a0 = "2016-08-08T00:00:00Z" |> parse_date!
    t1a = "2016-08-09T00:00:00Z" |> parse_date!
    values = Enum.map(samples11h1 |> Enum.slice(0..2), fn(s) -> s.value end)
    aggregates11h11 = Map.merge(aggr(values), %{"timestamp" => t1a |> format_date!,
                                                "from" => t1a0 |> format_date!,
                                                "to" => t1a |> format_date!,
                                                "granularity" => 60*60*24})

    t2a0 = "2016-08-09T00:00:00Z" |> parse_date!
    t2a = "2016-08-10T00:00:00Z" |> parse_date!
    values = Enum.map(samples11h1 |> Enum.slice(3..26), fn(s) -> s.value end)
    aggregates11h12 = Map.merge(aggr(values), %{"timestamp" => t2a |> format_date!,
                                                "from" => t2a0 |> format_date!,
                                                "to" => t2a |> format_date!,
                                                "granularity" => 60*60*24})

    t3a0 = "2016-08-10T00:00:00Z" |> parse_date!
    t3a = "2016-08-11T00:00:00Z" |> parse_date!
    values = Enum.map(samples11h1 |> Enum.slice(27..100), fn(s) -> s.value end)
    aggregates11h13 = Map.merge(aggr(values), %{"timestamp" => t3a |> format_date!,
                                                "from" => t3a0 |> format_date!,
                                                "to" => t3a |> format_date!,
                                                "granularity" => 60*60*24})

    conn = get conn, aggregate_path(conn, :show, %{metric: "metric1",
                                                   period: 3600,
                                                   granularity: 60*60*24,
                                                   projects: [project1.id],
                                                  })
    data = json_response(conn, 200)["data"]
    assert myround(Enum.at(data["id1"], 0)) == aggregates11h11
    assert myround(Enum.at(data["id1"], 1)) == aggregates11h12
    assert myround(Enum.at(data["id1"], 2)) == aggregates11h13
  end

  test "daily aggregation with outside data and ranges", %{conn: conn} do
    project1 = fixture(:project)
    metric1 = fixture(:metric)
    series11 = fixture(:series, project: project1, metric: metric1, period: 3600)

    t0 = "2016-08-08T22:00:00Z" |> parse_date!
    t1 = "2016-08-09T22:00:00Z" |> parse_date!

    samples11h1 = fixture(:samples, from: t0, repeat: 36, series: series11)

    values = Enum.map(samples11h1 |> Enum.slice(1..24), fn(s) -> s.value end)
    aggregates11h11 = Map.merge(aggr(values), %{"timestamp" => t1 |> format_date!,
                                                "from" => t0 |> format_date!,
                                                "to" => t1 |> format_date!,
                                                "granularity" => 60*60*24})

    conn = get conn, aggregate_path(conn, :show, %{metric: "metric1",
                                                   period: 3600,
                                                   from: t0 |> format_date!,
                                                   to: t1 |> format_date!,
                                                   granularity: 60*60*24,
                                                   projects: [project1.id],
                                                  })
    data = json_response(conn, 200)["data"]
    assert myround(Enum.at(data["id1"], 0)) == aggregates11h11
  end

  test "hourly aggregation with outside data and ranges", %{conn: conn} do
    project1 = fixture(:project)
    metric1 = fixture(:metric)
    series11 = fixture(:series, project: project1, metric: metric1, period: 3600)

    t0 = "2016-08-08T22:00:00Z" |> parse_date!
    t1 = "2016-08-09T22:00:00Z" |> parse_date!

    samples11h1 = fixture(:samples, from: t0, repeat: 37, series: series11)

    aggregates11h1n = samples11h1
    |> Enum.map(fn(s) -> s.value end)
    |> Enum.with_index
    |> Enum.map(fn({v, n}) -> Map.merge(aggr(v), %{"timestamp" => t0 |> Timex.shift(seconds: 3600*n) |> format_date!,
                                                  "from" => t0 |> Timex.shift(seconds: 3600*(n-1)) |> format_date!,
                                                  "to" => t0 |> Timex.shift(seconds: 3600*n) |> format_date!,
                                                  "granularity" => 60*60})
    end)

    conn = get conn, aggregate_path(conn, :show, %{metric: "metric1",
                                                   period: 3600,
                                                   from: t0 |> format_date!,
                                                   to: t1 |> format_date!,
                                                   granularity: 60*60,
                                                   projects: [project1.id],
                                                  })
    data = json_response(conn, 200)["data"]
    assert myround(data["id1"]) == aggregates11h1n |> Enum.slice(1..24)
  end

  test "daily aggregation with outside data and ranges and many series", %{conn: conn} do
    project1 = fixture(:project)
    project2 = fixture(:project, id: "id2", name: "project2")

    metric1 = fixture(:metric)
    metric2 = fixture(:metric, name: "metric2")

    series11h = fixture(:series, project: project1, metric: metric1, period: 3600)
    series12h = fixture(:series, project: project1, metric: metric2, period: 3600)
    series21h = fixture(:series, project: project2, metric: metric1, period: 3600)
    series22h = fixture(:series, project: project2, metric: metric2, period: 3600)
    series11d = fixture(:series, project: project1, metric: metric1, period: 3600*24)
    series12d = fixture(:series, project: project1, metric: metric2, period: 3600*24)
    series21d = fixture(:series, project: project2, metric: metric1, period: 3600*24)
    series22d = fixture(:series, project: project2, metric: metric2, period: 3600*24)

    t0 = "2016-08-08T16:00:00Z" |> parse_date!
    t1 = "2016-08-09T22:00:00Z" |> parse_date!
    t2 = "2016-08-12T22:00:00Z" |> parse_date!

    samples11h1 = fixture(:samples, from: t0, repeat: 100, series: series11h)
    samples21h1 = fixture(:samples, from: t0, repeat: 100, series: series21h)
    samples12d1 = fixture(:samples, from: t0, repeat: 100, series: series12d)

    t1a = "2016-08-09T22:00:00Z" |> parse_date!
    t1b0 = "2016-08-09T22:00:00Z" |> parse_date!
    t1b = "2016-08-10T22:00:00Z" |> parse_date!
    t1c0 = "2016-08-10T22:00:00Z" |> parse_date!
    t1c = "2016-08-11T22:00:00Z" |> parse_date!
    t1d0 = "2016-08-11T22:00:00Z" |> parse_date!
    t1d = "2016-08-12T22:00:00Z" |> parse_date!

    values = Enum.map(samples11h1 |> Enum.slice(31..54), fn(s) -> s.value end)
    aggregates11h11 = Map.merge(aggr(values), %{"timestamp" => t1b |> format_date!,
                                                "from" => t1b0 |> format_date!,
                                                "to" => t1b |> format_date!,
                                                "granularity" => 60*60*24})
    values = Enum.map(samples11h1 |> Enum.slice(55..78), fn(s) -> s.value end)
    aggregates11h12 = Map.merge(aggr(values), %{"timestamp" => t1c |> format_date!,
                                                "from" => t1c0 |> format_date!,
                                                "to" => t1c |> format_date!,
                                                "granularity" => 60*60*24})
    values = Enum.map(samples11h1 |> Enum.slice(79..100), fn(s) -> s.value end)
    aggregates11h13 = Map.merge(aggr(values), %{"timestamp" => t1d |> format_date!,
                                                "from" => t1d0 |> format_date!,
                                                "to" => t1d |> format_date!,
                                                "granularity" => 60*60*24})

    conn = get conn, aggregate_path(conn, :show, %{metric: "metric1",
                                                   period: 3600,
                                                   from: t1 |> format_date!,
                                                   to: t2 |> format_date!,
                                                   granularity: 60*60*24,
                                                   projects: [project1.id],
                                                  })


    data = json_response(conn, 200)["data"]
    assert myround(data["id1"]) == [aggregates11h11,
                                    aggregates11h12,
                                    aggregates11h13]
  end

  test "daily overall aggregation with outside data and ranges and many series", %{conn: conn} do
    project1 = fixture(:project)
    project2 = fixture(:project, id: "id2", name: "project2")

    metric1 = fixture(:metric)
    metric2 = fixture(:metric, name: "metric2")

    series11h = fixture(:series, project: project1, metric: metric1, period: 3600)
    series12h = fixture(:series, project: project1, metric: metric2, period: 3600)
    series21h = fixture(:series, project: project2, metric: metric1, period: 3600)
    series22h = fixture(:series, project: project2, metric: metric2, period: 3600)
    series11d = fixture(:series, project: project1, metric: metric1, period: 3600*24)
    series12d = fixture(:series, project: project1, metric: metric2, period: 3600*24)
    series21d = fixture(:series, project: project2, metric: metric1, period: 3600*24)
    series22d = fixture(:series, project: project2, metric: metric2, period: 3600*24)

    t0 = "2016-08-08T16:00:00Z" |> parse_date!
    t1 = "2016-08-09T22:00:00Z" |> parse_date!
    t2 = "2016-08-12T22:00:00Z" |> parse_date!

    samples11h1 = fixture(:samples, from: t0, repeat: 100, series: series11h)
    samples21h1 = fixture(:samples, from: t0, repeat: 100, series: series21h)
    samples12d1 = fixture(:samples, from: t0, repeat: 100, series: series12d)

    t1a = "2016-08-09T22:00:00Z" |> parse_date!
    t1b0 = "2016-08-09T22:00:00Z" |> parse_date!
    t1b = "2016-08-10T22:00:00Z" |> parse_date!
    t1c0 = "2016-08-10T22:00:00Z" |> parse_date!
    t1c = "2016-08-11T22:00:00Z" |> parse_date!
    t1d0 = "2016-08-11T22:00:00Z" |> parse_date!
    t1d = "2016-08-12T22:00:00Z" |> parse_date!

    values11h11 = Enum.map(samples11h1 |> Enum.slice(31..54), fn(s) -> s.value end)
    values21h11 = Enum.map(samples21h1 |> Enum.slice(31..54), fn(s) -> s.value end)
    values = values11h11 ++ values21h11
    aggregates11h11 = Map.merge(aggr(values), %{"timestamp" => t1b |> format_date!,
                                                "from" => t1b0 |> format_date!,
                                                "to" => t1b |> format_date!,
                                                "granularity" => 60*60*24})
    values11h12 = Enum.map(samples11h1 |> Enum.slice(55..78), fn(s) -> s.value end)
    values21h12 = Enum.map(samples21h1 |> Enum.slice(55..78), fn(s) -> s.value end)
    values = values11h12 ++ values21h12
    aggregates11h12 = Map.merge(aggr(values), %{"timestamp" => t1c |> format_date!,
                                                "from" => t1c0 |> format_date!,
                                                "to" => t1c |> format_date!,
                                                "granularity" => 60*60*24})
    values11h13 = Enum.map(samples11h1 |> Enum.slice(79..99), fn(s) -> s.value end)
    values21h13 = Enum.map(samples21h1 |> Enum.slice(79..99), fn(s) -> s.value end)
    values = values11h13 ++ values21h13
    aggregates11h13 = Map.merge(aggr(values), %{"timestamp" => t1d |> format_date!,
                                                "from" => t1d0 |> format_date!,
                                                "to" => t1d |> format_date!,
                                                "granularity" => 60*60*24})

    conn = get conn, aggregate_path(conn, :show, %{metric: "metric1",
                                                   period: 3600,
                                                   from: t1 |> format_date!,
                                                   to: t2 |> format_date!,
                                                   granularity: 60*60*24,
                                                   projects: [],
                                                  })


    data = json_response(conn, 200)["data"]
    assert myround(data) == [aggregates11h11,
                             aggregates11h12,
                             aggregates11h13]
  end

  test "daily aggregation with linear data with outside data and ranges and many series", %{conn: conn} do
    project1 = fixture(:project)
    project2 = fixture(:project, id: "id2", name: "project2")

    metric1 = fixture(:metric)
    metric2 = fixture(:metric, name: "metric2")

    series11h = fixture(:series, project: project1, metric: metric1, period: 3600)
    series12h = fixture(:series, project: project1, metric: metric2, period: 3600)
    series21h = fixture(:series, project: project2, metric: metric1, period: 3600)
    series22h = fixture(:series, project: project2, metric: metric2, period: 3600)
    series11d = fixture(:series, project: project1, metric: metric1, period: 3600*24)
    series12d = fixture(:series, project: project1, metric: metric2, period: 3600*24)
    series21d = fixture(:series, project: project2, metric: metric1, period: 3600*24)
    series22d = fixture(:series, project: project2, metric: metric2, period: 3600*24)

    t0 = "2016-10-02T22:00:00Z" |> parse_date!
    t1 = "2016-10-03T22:00:00Z" |> parse_date!
    t2 = "2016-10-04T22:00:00Z" |> parse_date!
    t3 = "2016-10-05T22:00:00Z" |> parse_date!
    t4 = "2016-10-06T22:00:00Z" |> parse_date!

    samples11h1 = fixture(:samples, from: t0, repeat: 100, series: series11h, values: :linear)
    samples21h1 = fixture(:samples, from: t0, repeat: 100, series: series21h, values: :linear)
    samples12d1 = fixture(:samples, from: t0, repeat: 100, series: series12d, values: :linear)

    values11h11 = Enum.map(samples11h1 |> Enum.slice(1..24), fn(s) -> s.value end)
    values = values11h11
    aggregates11h11 = Map.merge(aggr(values), %{"from" => t0 |> format_date!,
                                                "to" => t1 |> format_date!,
                                                "timestamp" => t1 |> format_date!,
                                                "granularity" => 60*60*24})

    values11h12 = Enum.map(samples11h1 |> Enum.slice(25..48), fn(s) -> s.value end)
    values = values11h12
    aggregates11h12 = Map.merge(aggr(values), %{"from" => t1 |> format_date!,
                                                "to" => t2 |> format_date!,
                                                "timestamp" => t2 |> format_date!,
                                                "granularity" => 60*60*24})

    values11h13 = Enum.map(samples11h1 |> Enum.slice(49..72), fn(s) -> s.value end)
    values = values11h13
    aggregates11h13 = Map.merge(aggr(values), %{"from" => t2 |> format_date!,
                                                "to" => t3 |> format_date!,
                                                "timestamp" => t3 |> format_date!,
                                                "granularity" => 60*60*24})

    values11h14 = Enum.map(samples11h1 |> Enum.slice(73..96), fn(s) -> s.value end)
    values = values11h14
    aggregates11h14 = Map.merge(aggr(values), %{"from" => t3 |> format_date!,
                                                "to" => t4 |> format_date!,
                                                "timestamp" => t4 |> format_date!,
                                                "granularity" => 60*60*24})

    conn = get conn, aggregate_path(conn, :show, %{metric: "metric1",
                                                   period: 3600,
                                                   from: t0 |> format_date!,
                                                   to: t4 |> format_date!,
                                                   granularity: 60*60*24,
                                                   projects: [project1.id],
                                                  })

    data = json_response(conn, 200)["data"]


    assert myround(data[project1.id]) == [aggregates11h11,
                                          aggregates11h12,
                                          aggregates11h13,
                                          aggregates11h14]

    assert data[project1.id] |> Enum.map(fn(x) -> x["sum"] end) == [324, 900, 1476, 2052]
  end

end
