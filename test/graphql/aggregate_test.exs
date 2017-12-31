################################################################################
#
# caos-tsdb - CAOS Time-Series DB
#
# Copyright © 2016, 2017, 2018 INFN - Istituto Nazionale di Fisica Nucleare (Italy)
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
  query($series: SeriesGroup!, $from: Datetime, $to: Datetime, $granularity: Int, $function: AggregateFunction, $downsample: AggregateFunction, $fill: FillPolicy) {
    aggregate(series: $series, from: $from, to: $to, granularity: $granularity, function: $function, downsample: $downsample, fill: $fill) {
      timestamp
      value
    }
  }
  """

  @query_params %{series: %{metric: %{name: "metric1"}, period: 3600},
                  fill: "NONE",
                  granularity: 60*60*24, function: "SUM", downsample: "NONE"}

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

    assert graphql_data(new_conn) == expected_json
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

    assert graphql_data(new_conn) == expected_json
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

    assert graphql_data(new_conn) == expected_json
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

    assert graphql_data(new_conn) == expected_json
  end

  test "aggregate one series with ZERO fill", %{conn: conn} do
    tag1 = fixture(:tag)
    metric1 = fixture(:metric)
    series11 = fixture(:series, tags: [tag1], metric: metric1, period: 3600)

    t0 = "2016-08-08T22:00:00Z" |> parse_date!

    t_from = t0 |> Timex.shift(hours: -24*2)
    t_to = t0 |> Timex.shift(hours: 24*4)

    samples11h1 = fixture(:samples, from: t0, repeat: 30, series: series11, values: :linear)

    query_params = @query_params
    |> put_in([:from], t_from |> format_date!)
    |> put_in([:to], t_to |> format_date!)
    |> put_in([:series, :tags], [%{id: tag1.id}])
    |> put_in([:function], "SUM")
    |> put_in([:fill], "ZERO")

    new_conn = graphql_query conn, @query, query_params

    expected_json = %{"aggregate" => fixture(:aggregate, [samples11h1], query_params) |> samples_to_json([:timestamp, :value]) }

    assert graphql_data(new_conn) == expected_json
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

    assert graphql_data(new_conn) == expected_json
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

    assert graphql_data(new_conn) == expected_json
  end

  test "downsample over many tags", %{conn: conn} do
    tag1 = fixture(:tag, key: "key", value: "value1")
    tag2 = fixture(:tag, key: "key", value: "value2")
    tag31 = fixture(:tag, key: "key3", value: "value3")

    metric1 = fixture(:metric)
    metric2 = fixture(:metric, name: "metric2")

    series11h = fixture(:series, tags: [tag1], metric: metric1, period: 3600)
    _series12h = fixture(:series, tags: [tag1], metric: metric2, period: 3600)
    series21h = fixture(:series, tags: [tag2], metric: metric1, period: 3600)
    _series22h = fixture(:series, tags: [tag2], metric: metric2, period: 3600)
    series31h = fixture(:series, tags: [tag31], metric: metric1, period: 3600)
    _series11d = fixture(:series, tags: [tag1], metric: metric1, period: 3600*24)
    series12d = fixture(:series, tags: [tag1], metric: metric2, period: 3600*24)
    _series21d = fixture(:series, tags: [tag2], metric: metric1, period: 3600*24)
    _series22d = fixture(:series, tags: [tag2], metric: metric2, period: 3600*24)

    t0 = "2016-08-08T16:00:00Z" |> parse_date!
    t1 = "2016-08-09T22:00:00Z" |> parse_date!
    t2 = "2016-08-12T22:00:00Z" |> parse_date!

    samples11h1 = fixture(:samples, from: t0, start_value: 0, repeat: 100, series: series11h, values: :linear)
    samples21h1 = fixture(:samples, from: t0, start_value: 200, repeat: 100, series: series21h, values: :linear)
    _samples31h1 = fixture(:samples, from: t0, start_value: 200, repeat: 100, series: series31h, values: :linear)
    _samples12d1 = fixture(:samples, from: t0, repeat: 100, series: series12d, values: :linear)

    query_params = @query_params
    |> put_in([:series, :tag], %{key: tag1.key})
    |> put_in([:from], t1 |> format_date!)
    |> put_in([:to], t2 |> format_date!)
    |> put_in([:downsample], "AVG")
    |> put_in([:function], "NONE")

    new_conn = graphql_query conn, @query, query_params

    expected_json = %{"aggregate" => fixture(:aggregate, [samples11h1, samples21h1], query_params) |> samples_to_json([:timestamp, :value]) }

    assert graphql_data(new_conn) == expected_json
  end

  test "downsample and aggregate over many tags", %{conn: conn} do
    tag1 = fixture(:tag, key: "key", value: "value1")
    tag2 = fixture(:tag, key: "key", value: "value2")
    tag31 = fixture(:tag, key: "key3", value: "value3")

    metric1 = fixture(:metric)
    metric2 = fixture(:metric, name: "metric2")

    series11h = fixture(:series, tags: [tag1], metric: metric1, period: 3600)
    _series12h = fixture(:series, tags: [tag1], metric: metric2, period: 3600)
    series21h = fixture(:series, tags: [tag2], metric: metric1, period: 3600)
    _series22h = fixture(:series, tags: [tag2], metric: metric2, period: 3600)
    series31h = fixture(:series, tags: [tag31], metric: metric1, period: 3600)
    _series11d = fixture(:series, tags: [tag1], metric: metric1, period: 3600*24)
    series12d = fixture(:series, tags: [tag1], metric: metric2, period: 3600*24)
    _series21d = fixture(:series, tags: [tag2], metric: metric1, period: 3600*24)
    _series22d = fixture(:series, tags: [tag2], metric: metric2, period: 3600*24)

    t0 = "2016-08-08T16:00:00Z" |> parse_date!
    t1 = "2016-08-09T22:00:00Z" |> parse_date!
    t2 = "2016-08-12T22:00:00Z" |> parse_date!

    samples11h1 = fixture(:samples, from: t0, start_value: 0, repeat: 100, series: series11h, values: :linear)
    samples21h1 = fixture(:samples, from: t0, start_value: 200, repeat: 100, series: series21h, values: :linear)
    _samples31h1 = fixture(:samples, from: t0, start_value: 200, repeat: 100, series: series31h, values: :linear)
    _samples12d1 = fixture(:samples, from: t0, repeat: 100, series: series12d, values: :linear)

    query_params = @query_params
    |> put_in([:series, :tag], %{key: tag1.key})
    |> put_in([:from], t1 |> format_date!)
    |> put_in([:to], t2 |> format_date!)
    |> put_in([:downsample], "AVG")
    |> put_in([:function], "SUM")

    new_conn = graphql_query conn, @query, query_params

    expected_json = %{"aggregate" => fixture(:aggregate, [samples11h1, samples21h1], query_params) |> samples_to_json([:timestamp, :value]) }

    assert graphql_data(new_conn) == expected_json
  end

  test "aggregate from a tag", %{conn: conn} do
    query = """
    query($tag_key: String!, $tag_value: String, $period: Int!, $metric_name: String!, $from: Datetime!, $to: Datetime!, $granularity: Int, $function: AggregateFunction) {
      tag(key: $tag_key, value: $tag_value) {
        series(tags: [], metric: {name: $metric_name}, period: $period) {
          aggregate(from: $from, to: $to, granularity: $granularity, function: $function) {
            timestamp
            value
          }
        }
        id
        key
        value
      }
    }
    """

    query_params = %{granularity: 60*60*24, function: "SUM", period: 3600,
                     from: nil, to: nil}

    tag11 = fixture(:tag, key: "key1", value: "value1")
    tag12 = fixture(:tag, key: "key1", value: "value2")
    tag21 = fixture(:tag, key: "key2", value: "value1")
    tag22 = fixture(:tag, key: "key2", value: "value2")

    metric1 = fixture(:metric)
    metric2 = fixture(:metric, name: "metric2")

    series111h = fixture(:series, tags: [tag11], metric: metric1, period: 3600)
    series112h = fixture(:series, tags: [tag11], metric: metric2, period: 3600)
    _series211h = fixture(:series, tags: [tag21], metric: metric1, period: 3600)
    _series212h = fixture(:series, tags: [tag21], metric: metric2, period: 3600)
    _series121h = fixture(:series, tags: [tag12], metric: metric1, period: 3600)
    _series122h = fixture(:series, tags: [tag12], metric: metric2, period: 3600)
    _series221h = fixture(:series, tags: [tag22], metric: metric1, period: 3600)
    _series222h = fixture(:series, tags: [tag22], metric: metric2, period: 3600)
    series111d = fixture(:series, tags: [tag11], metric: metric1, period: 3600*24)
    _series112d = fixture(:series, tags: [tag11], metric: metric2, period: 3600*24)
    _series211d = fixture(:series, tags: [tag21], metric: metric1, period: 3600*24)
    _series212d = fixture(:series, tags: [tag21], metric: metric2, period: 3600*24)

    t0 = "2016-08-08T16:00:00Z" |> parse_date!
    t1 = "2016-08-09T22:00:00Z" |> parse_date!
    t2 = "2016-08-12T22:00:00Z" |> parse_date!

    samples111h1 = fixture(:samples, from: t0, repeat: 100, series: series111h, values: :linear)
    _samples112h1 = fixture(:samples, from: t0, repeat: 100, series: series112h, values: :linear)
    _samples111d1 = fixture(:samples, from: t0, repeat: 100, series: series111d, values: :linear)

    query_params = query_params
    |> put_in([:from], t1 |> format_date!)
    |> put_in([:to], t2 |> format_date!)
    |> put_in([:tag_key], tag11.key)
    |> put_in([:tag_value], tag11.value)
    |> put_in([:metric_name], metric1.name)

    new_conn = graphql_query conn, query, query_params

    expected_json = %{"tag" => tag_to_json(tag11) }
    |> put_in(["tag", "series"], [%{"aggregate" => fixture(:aggregate, [samples111h1], query_params) |> samples_to_json([:timestamp, :value])}])

    assert graphql_data(new_conn) == expected_json
  end

  test "downsample and aggregate with series with many tags", %{conn: conn} do
    tagA1 = fixture(:tag, key: "keyA", value: "valueA1")
    tagA2 = fixture(:tag, key: "keyA", value: "valueA2")
    tagB1 = fixture(:tag, key: "keyB", value: "valueB1")
    tagB2 = fixture(:tag, key: "keyB", value: "valueB2")

    metric1 = fixture(:metric, name: "metric1")
    metric2 = fixture(:metric, name: "metric2")

    series1_A1 = fixture(:series, tags: [tagA1], metric: metric1, period: 0)
    series1_A2 = fixture(:series, tags: [tagA2], metric: metric1, period: 0)
    series1_A1B1 = fixture(:series, tags: [tagA1, tagB1], metric: metric1, period: 0)
    series1_A1B2 = fixture(:series, tags: [tagA1, tagB2], metric: metric1, period: 0)
    series1_A2B1 = fixture(:series, tags: [tagA2, tagB1], metric: metric1, period: 0)
    series1_A2B2 = fixture(:series, tags: [tagA2, tagB2], metric: metric1, period: 0)

    t0 = "2016-08-08T16:00:00Z" |> parse_date!
    t1 = "2016-08-08T17:00:00Z" |> parse_date!
    t2 = "2016-08-23T22:00:00Z" |> parse_date!

    samples1_A1 = fixture(:samples, from: t0, values: :linear, time_shift: 300, repeat: 10, start_value: 0, series: series1_A1)
    samples1_A2 = fixture(:samples, from: t0, values: :linear, time_shift: 300, repeat: 10, start_value: 2, series: series1_A2)
    samples1_A1B1 = fixture(:samples, from: t0, values: :linear, time_shift: 300, repeat: 10, start_value: 4, series: series1_A1B1)
    samples1_A1B2 = fixture(:samples, from: t0, values: :linear, time_shift: 300, repeat: 10, start_value: 3, series: series1_A1B2)
    samples1_A2B1 = fixture(:samples, from: t0, values: :linear, time_shift: 300, repeat: 10, start_value: 6, series: series1_A2B1)
    samples1_A2B2 = fixture(:samples, from: t0, values: :linear, time_shift: 300, repeat: 10, start_value: 5, series: series1_A2B2)

    base_query_params = @query_params
    |> put_in([:series, :period], 0)
    |> put_in([:from], t1 |> format_date!)
    |> put_in([:to], t2 |> format_date!)
    |> put_in([:downsample], "AVG")
    |> put_in([:function], "SUM")

    query_params = base_query_params
    |> put_in([:series, :tags], [%{key: tagB1.key, value: tagB1.value}])
    |> put_in([:series, :tag], %{key: tagA1.key})

    new_conn = graphql_query conn, @query, query_params
    expected_json = %{"aggregate" => fixture(:aggregate, [samples1_A1B1, samples1_A2B1], query_params) |> samples_to_json([:timestamp, :value]) }
    assert graphql_data(new_conn) == expected_json


    query_params = base_query_params
    |> put_in([:series, :tag], %{key: tagA1.key})

    new_conn = graphql_query conn, @query, query_params
    expected_json = %{"aggregate" => fixture(:aggregate, [samples1_A1, samples1_A2], query_params) |> samples_to_json([:timestamp, :value]) }
    assert graphql_data(new_conn) == expected_json

  end
end
