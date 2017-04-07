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

defmodule CaosTsdb.Graphql.AggregateTest do
  use CaosTsdb.ConnCase

  import CaosTsdb.DateTime.Helpers

  setup %{conn: conn} do
    conn = conn
    |> put_req_header("accept", "application/json")
    |> put_valid_token()

    {:ok, conn: conn}
  end

  @query """
  query($series: SeriesGroup!, $from: Datetime!, $to: Datetime!, $granularity: Int, $function: AggregateFunction) {
    aggregate(series: $series, from: $from, to: $to, granularity: $granularity, function: $function) {
      timestamp
      value
    }
  }
  """

  @query_params %{series: %{metric: %{name: "metric1"}, period: 3600},
                  granularity: 60*60*24, function: "SUM",
                  from: nil, to: nil}

  test "downsample with hourly granularity", %{conn: conn} do
    tag1 = fixture(:tag)
    metric1 = fixture(:metric)
    series11 = fixture(:series, tags: [tag1], metric: metric1, period: 3600)

    t0 = "2016-08-08T22:00:00Z" |> parse_date!
    _t1 = "2016-08-09T22:00:00Z" |> parse_date!

    samples11h1 = fixture(:samples, from: t0, repeat: 30, series: series11, values: :linear)

    query_params = @query_params
    |> put_in([:series, :tags], [%{id: tag1.id}])
    |> put_in([:granularity], 60*60)
    new_conn = graphql_query conn, @query, query_params

    expected_json = %{"aggregate" => fixture(:aggregate, [samples11h1], query_params) |> samples_to_json([:timestamp, :value]) }

    assert json_response(new_conn, 200)["data"] == expected_json
  end

  test "daily downsample with one series", %{conn: conn} do
    tag1 = fixture(:tag)
    metric1 = fixture(:metric)
    series11 = fixture(:series, tags: [tag1], metric: metric1, period: 3600)

    t0 = "2016-08-08T22:00:00Z" |> parse_date!
    _t1 = "2016-08-09T22:00:00Z" |> parse_date!

    samples11h1 = fixture(:samples, from: t0, repeat: 30, series: series11, values: :linear)

    query_params = @query_params
    |> put_in([:series, :tags], [%{id: tag1.id}])

    new_conn = graphql_query conn, @query, query_params

    expected_json = %{"aggregate" => fixture(:aggregate, [samples11h1], query_params) |> samples_to_json([:timestamp, :value]) }

    assert json_response(new_conn, 200)["data"] == expected_json
  end

  test "daily downsample with many series", %{conn: conn} do
    tag1 = fixture(:tag)
    tag2 = fixture(:tag, key: "key2", value: "value2")

    metric1 = fixture(:metric)
    metric2 = fixture(:metric, name: "metric2")

    series11h = fixture(:series, tags: [tag1], metric: metric1, period: 3600)
    _series12h = fixture(:series, tags: [tag1], metric: metric2, period: 3600)
    series21h = fixture(:series, tags: [tag2], metric: metric1, period: 3600)
    _series22h = fixture(:series, tags: [tag2], metric: metric2, period: 3600)
    _series11d = fixture(:series, tags: [tag1], metric: metric1, period: 3600*24)
    series12d = fixture(:series, tags: [tag1], metric: metric2, period: 3600*24)
    _series21d = fixture(:series, tags: [tag2], metric: metric1, period: 3600*24)
    _series22d = fixture(:series, tags: [tag2], metric: metric2, period: 3600*24)

    t0 = "2016-08-08T16:00:00Z" |> parse_date!
    t1 = "2016-08-09T22:00:00Z" |> parse_date!
    t2 = "2016-08-12T22:00:00Z" |> parse_date!

    samples11h1 = fixture(:samples, from: t0, repeat: 100, series: series11h, values: :linear)
    _samples21h1 = fixture(:samples, from: t0, repeat: 100, series: series21h, values: :linear)
    _samples12d1 = fixture(:samples, from: t0, repeat: 100, series: series12d, values: :linear)

    query_params = @query_params
    |> put_in([:series, :tags], [%{id: tag1.id}])
    |> put_in([:from], t1 |> format_date!)
    |> put_in([:to], t2 |> format_date!)

    new_conn = graphql_query conn, @query, query_params

    expected_json = %{"aggregate" => fixture(:aggregate, [samples11h1], query_params) |> samples_to_json([:timestamp, :value]) }

    assert json_response(new_conn, 200)["data"] == expected_json
  end

  test "aggregate one series", %{conn: conn} do
    tag1 = fixture(:tag)
    metric1 = fixture(:metric)
    series11 = fixture(:series, tags: [tag1], metric: metric1, period: 3600)

    t0 = "2016-08-08T22:00:00Z" |> parse_date!
    _t1 = "2016-08-09T22:00:00Z" |> parse_date!

    samples11h1 = fixture(:samples, from: t0, repeat: 30, series: series11, values: :linear)

    query_params = @query_params
    |> put_in([:series, :tags], [%{id: tag1.id}])
    |> put_in([:function], "SUM")

    new_conn = graphql_query conn, @query, query_params

    expected_json = %{"aggregate" => fixture(:aggregate, [samples11h1], query_params) |> samples_to_json([:timestamp, :value]) }

    assert json_response(new_conn, 200)["data"] == expected_json
  end

  test "aggregate with many series", %{conn: conn} do
    tag1 = fixture(:tag)
    tag2 = fixture(:tag, key: "key2", value: "value2")

    metric1 = fixture(:metric)
    metric2 = fixture(:metric, name: "metric2")

    series11h = fixture(:series, tags: [tag1], metric: metric1, period: 3600)
    _series12h = fixture(:series, tags: [tag1], metric: metric2, period: 3600)
    series21h = fixture(:series, tags: [tag2], metric: metric1, period: 3600)
    _series22h = fixture(:series, tags: [tag2], metric: metric2, period: 3600)
    _series11d = fixture(:series, tags: [tag1], metric: metric1, period: 3600*24)
    series12d = fixture(:series, tags: [tag1], metric: metric2, period: 3600*24)
    _series21d = fixture(:series, tags: [tag2], metric: metric1, period: 3600*24)
    _series22d = fixture(:series, tags: [tag2], metric: metric2, period: 3600*24)

    t0 = "2016-08-08T16:00:00Z" |> parse_date!
    t1 = "2016-08-09T22:00:00Z" |> parse_date!
    t2 = "2016-08-12T22:00:00Z" |> parse_date!

    samples11h1 = fixture(:samples, from: t0, repeat: 100, series: series11h, values: :linear)
    _samples21h1 = fixture(:samples, from: t0, repeat: 100, series: series21h, values: :linear)
    _samples12d1 = fixture(:samples, from: t0, repeat: 100, series: series12d, values: :linear)

    query_params = @query_params
    |> put_in([:series, :tags], [%{id: tag1.id}])
    |> put_in([:from], t1 |> format_date!)
    |> put_in([:to], t2 |> format_date!)
    |> put_in([:function], "SUM")

    new_conn = graphql_query conn, @query, query_params

    expected_json = %{"aggregate" => fixture(:aggregate, [samples11h1], query_params) |> samples_to_json([:timestamp, :value]) }

    assert json_response(new_conn, 200)["data"] == expected_json
  end

  test "aggregate over many tags", %{conn: conn} do
    tag1 = fixture(:tag, key: "key", value: "value1")
    tag2 = fixture(:tag, key: "key", value: "value2")

    metric1 = fixture(:metric)
    metric2 = fixture(:metric, name: "metric2")

    series11h = fixture(:series, tags: [tag1], metric: metric1, period: 3600)
    _series12h = fixture(:series, tags: [tag1], metric: metric2, period: 3600)
    series21h = fixture(:series, tags: [tag2], metric: metric1, period: 3600)
    _series22h = fixture(:series, tags: [tag2], metric: metric2, period: 3600)
    _series11d = fixture(:series, tags: [tag1], metric: metric1, period: 3600*24)
    series12d = fixture(:series, tags: [tag1], metric: metric2, period: 3600*24)
    _series21d = fixture(:series, tags: [tag2], metric: metric1, period: 3600*24)
    _series22d = fixture(:series, tags: [tag2], metric: metric2, period: 3600*24)

    t0 = "2016-08-08T16:00:00Z" |> parse_date!
    t1 = "2016-08-09T22:00:00Z" |> parse_date!
    t2 = "2016-08-12T22:00:00Z" |> parse_date!

    samples11h1 = fixture(:samples, from: t0, repeat: 100, series: series11h, values: :linear)
    samples21h1 = fixture(:samples, from: t0, repeat: 100, series: series21h, values: :linear)
    _samples12d1 = fixture(:samples, from: t0, repeat: 100, series: series12d, values: :linear)

    query_params = @query_params
    |> put_in([:series, :tag], %{key: tag1.key})
    |> put_in([:from], t1 |> format_date!)
    |> put_in([:to], t2 |> format_date!)
    |> put_in([:function], "SUM")

    new_conn = graphql_query conn, @query, query_params

    expected_json = %{"aggregate" => fixture(:aggregate, [samples11h1, samples21h1], query_params) |> samples_to_json([:timestamp, :value]) }

    assert json_response(new_conn, 200)["data"] == expected_json
  end
end
