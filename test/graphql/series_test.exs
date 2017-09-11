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

defmodule CaosTsdb.Graphql.SeriesTest do
  use CaosTsdb.ConnCase

  import CaosTsdb.DateTime.Helpers

  setup %{conn: conn} do
    conn = conn
    |> put_req_header("accept", "application/json")
    |> put_valid_token()

    {:ok, conn: conn}
  end

  describe "failure on" do
    test "series query without arguments", %{conn: conn} do
      query = """
      query {
        series {
          period
          metric {
            name
          }
          tags {
            id
            key
            value
          }
          last_timestamp
          ttl
        }
      }
      """

      conn = graphql_query conn, query
      assert_graphql_errors(conn)
    end
  end

  describe "get series by id" do
    @query """
    query($id: ID!) {
      series(id: $id) {
        id
        period
        metric {
          name
        }
        tags {
          id
          key
          value
        }
        last_timestamp
        ttl
      }
    }
    """

    test "should fail when there are no series", %{conn: conn} do
      conn = graphql_query conn, @query, %{id: -1}
      assert_graphql_errors(conn)
    end

    test "when there is one series", %{conn: conn} do
      series1 = fixture(:series)

      conn = graphql_query conn, @query, %{id: series1.id}
      assert graphql_data(conn) == %{"series" => series_to_json(series1)}
    end

    test "when there are many series and many tags", %{conn: conn} do
      tag1 = fixture(:tag, key: "key1", value: "value1")
      tag2 = fixture(:tag, key: "key2", value: "value2")
      _tag3 = fixture(:tag, key: "key3", value: "value3")

      metric1 = fixture(:metric, name: "metric1")
      _metric2 = fixture(:metric, name: "metric2")

      _series1 = fixture(:series, tags: [tag1], metric: metric1, period: 3600)
      series2 = fixture(:series, tags: [tag1, tag2], metric: metric1, period: 3600)
      _series3 = fixture(:series, tags: [tag1], metric: metric1, period: 86400)

      conn = graphql_query conn, @query, %{id: series2.id}
      assert graphql_data(conn) == %{"series" => series_to_json(series2)}
    end
  end

  describe "get series by period/metric/tags" do
    @query """
    query($period: Int!, $metric: MetricPrimary!, $tags: [TagPrimary]!) {
      series(period: $period, metric: $metric, tags: $tags) {
        id
        period
        metric {
          name
        }
        tags {
          id
          key
          value
        }
        last_timestamp
        ttl
      }
    }
    """

    @query_params %{period: 3600, metric: %{name: "metric1"}, tags: []}

    test "should fail when there are no parameters", %{conn: conn} do
      conn = graphql_query conn, @query
      assert_graphql_errors(conn, 400)
    end

    test "should fail when there are no series", %{conn: conn} do
      conn = graphql_query conn, @query, @query_params
      assert_graphql_errors(conn)
    end

    test "should fail when there are many matches", %{conn: conn} do
      tag1 = fixture(:tag, key: "key1", value: "value1")
      tag2 = fixture(:tag, key: "key2", value: "value2")
      tag3 = fixture(:tag, key: "key3", value: "value3")

      metric1 = fixture(:metric, name: "metric1")
      _metric2 = fixture(:metric, name: "metric2")

      _series1 = fixture(:series, tags: [tag1], metric: metric1, period: 3600)
      _series2 = fixture(:series, tags: [tag1, tag2], metric: metric1, period: 3600)
      _series3 = fixture(:series, tags: [tag1, tag2, tag3], metric: metric1, period: 86400)

      conn = graphql_query conn, @query, %{@query_params | tags: [%{id: tag1.id}]}
      assert_graphql_errors(conn)
    end

    test "when there is one series", %{conn: conn} do
      tag1 = fixture(:tag, key: "key1", value: "value1")
      tag2 = fixture(:tag, key: "key2", value: "value2")
      _tag3 = fixture(:tag, key: "key3", value: "value3")

      metric1 = fixture(:metric, name: "metric1")
      _metric2 = fixture(:metric, name: "metric2")

      series2 = fixture(:series, tags: [tag1, tag2], metric: metric1, period: 3600)

      conn = graphql_query conn, @query, %{@query_params | tags: [%{id: tag1.id}, %{id: tag2.id}]}
      assert graphql_data(conn) == %{"series" => series_to_json(series2)}
    end

    test "when there are many series", %{conn: conn} do
      tag1 = fixture(:tag, key: "key1", value: "value1")
      tag2 = fixture(:tag, key: "key2", value: "value2")
      tag3 = fixture(:tag, key: "key3", value: "value3")

      metric1 = fixture(:metric, name: "metric1")
      _metric2 = fixture(:metric, name: "metric2")

      _series1 = fixture(:series, tags: [tag1], metric: metric1, period: 3600)
      series2 = fixture(:series, tags: [tag1, tag2], metric: metric1, period: 3600)
      _series3 = fixture(:series, tags: [tag1, tag2, tag3], metric: metric1, period: 86400)

      conn = graphql_query conn, @query, %{@query_params | tags: [%{key: tag2.key, value: tag2.value}, %{id: tag1.id}]}
      assert graphql_data(conn) == %{"series" => series_to_json(series2)}
    end
  end

  describe "create series" do
    @query """
    mutation($period: Int!, $metric: MetricPrimary!, $tags: [TagPrimary!]!) {
      series: create_series(period: $period, metric: $metric, tags: $tags) {
        id
        period
        metric {
          name
        }
        tags {
          id
          key
          value
        }
        last_timestamp
        ttl
      }
    }
    """

    @query_params %{period: 3600, metric: %{name: "metric1"}, tags: []}

    test "when data is valid", %{conn: conn} do
      tag1 = fixture(:tag, key: "key1", value: "value1")
      tag2 = fixture(:tag, key: "key2", value: "value2")
      tag3 = fixture(:tag, key: "key3", value: "value3")

      metric1 = fixture(:metric, name: "metric1")
      _metric2 = fixture(:metric, name: "metric2")

      series1 = fixture(:series, tags: [tag1, tag2], metric: metric1, period: 3600)

      conn = graphql_query conn, @query, %{@query_params | tags: [%{id: tag1.id}, %{id: tag3.id}]}
      expected_json = series_to_json(series1)
      |> put_in(["tags"], tags_to_json([tag1, tag3]))
      |> Map.drop(["id"])
      assert graphql_data(conn)["series"] |> Map.drop(["id"]) == expected_json
    end

    test "must fail when no tag is given", %{conn: conn} do
      tag1 = fixture(:tag, key: "key1", value: "value1")
      tag2 = fixture(:tag, key: "key2", value: "value2")
      _tag3 = fixture(:tag, key: "key3", value: "value3")

      metric1 = fixture(:metric, name: "metric1")
      _metric2 = fixture(:metric, name: "metric2")

      _series1 = fixture(:series, tags: [tag1, tag2], metric: metric1, period: 3600)

      conn = graphql_query conn, @query, @query_params
      assert_graphql_errors(conn)
    end

    test "returns already existent series", %{conn: conn} do
      tag1 = fixture(:tag, key: "key1", value: "value1")
      tag2 = fixture(:tag, key: "key2", value: "value2")
      tag3 = fixture(:tag, key: "key3", value: "value3")

      metric1 = fixture(:metric, name: "metric1")
      _metric2 = fixture(:metric, name: "metric2")

      _series1 = fixture(:series, tags: [tag1, tag2], metric: metric1, period: 3600)
      series2 = fixture(:series, tags: [tag1, tag3], metric: metric1, period: 3600)
      _series3 = fixture(:series, tags: [tag1, tag2, tag3], metric: metric1, period: 3600)

      conn = graphql_query conn, @query, %{@query_params | tags: [%{id: tag1.id}, %{id: tag3.id}]}
      expected_json = %{"series" => series_to_json(series2)}
      assert graphql_data(conn) == expected_json
    end
  end

  describe "get series subfield" do
    @query """
    query($period: Int!, $metric: MetricPrimary!, $tags: [TagPrimary]!, $timestamp: Datetime!) {
      series(period: $period, metric: $metric, tags: $tags) {
        id
        period
        metric {
          name
        }
        tags {
          id
          key
          value
        }
        last_timestamp
        ttl
        sample(timestamp: $timestamp) {
          timestamp
          value
          series {
            id
          }
          updated_at
          inserted_at
        }
      }
    }
    """

    @query_params %{period: 3600, metric: %{name: "metric1"}, tags: [], timestamp: nil}

    test "should fail when there are no parameters", %{conn: conn} do
      conn = graphql_query conn, @query
      assert_graphql_errors(conn, 400)
    end

    test "should fail when there are no series", %{conn: conn} do
      conn = graphql_query conn, @query, @query_params
      assert_graphql_errors(conn, 400)
    end

    test "should not fail when sample is not found", %{conn: conn} do
      tag1 = fixture(:tag, key: "key1", value: "value1")
      tag2 = fixture(:tag, key: "key2", value: "value2")
      tag3 = fixture(:tag, key: "key3", value: "value3")

      metric1 = fixture(:metric, name: "metric1")
      _metric2 = fixture(:metric, name: "metric2")

      series1 = fixture(:series, tags: [tag1], metric: metric1, period: 3600)
      series2 = fixture(:series, tags: [tag1, tag2], metric: metric1, period: 3600)
      series3 = fixture(:series, tags: [tag1, tag2, tag3], metric: metric1, period: 86400)

      t0 = "2016-08-08T16:00:00Z" |> parse_date!

      _samples1 = fixture(:samples, from: t0, repeat: 100, series: series1, values: :linear)
      _samples2 = fixture(:samples, from: t0, repeat: 100, series: series2, values: :linear)
      _samples3 = fixture(:samples, from: t0, repeat: 100, series: series3, values: :linear)

      query_params = @query_params
      |> put_in([:tags], [%{id: tag1.id}])
      |> put_in([:timestamp], epoch() |> format_date!)

      conn = graphql_query conn, @query, query_params
      refute_graphql_errors(conn)
    end

    test "when there are many series", %{conn: conn} do
      tag1 = fixture(:tag, key: "key1", value: "value1")
      tag2 = fixture(:tag, key: "key2", value: "value2")
      tag3 = fixture(:tag, key: "key3", value: "value3")

      metric1 = fixture(:metric, name: "metric1")
      _metric2 = fixture(:metric, name: "metric2")

      series1 = fixture(:series, tags: [tag1], metric: metric1, period: 3600)
      series2 = fixture(:series, tags: [tag1, tag2], metric: metric1, period: 3600)
      series3 = fixture(:series, tags: [tag1, tag2, tag3], metric: metric1, period: 86400)

      t0 = "2016-08-08T16:00:00Z" |> parse_date!

      _samples1 = fixture(:samples, from: t0, repeat: 100, series: series1, values: :linear)
      samples2 = fixture(:samples, from: t0, repeat: 100, series: series2, values: :linear)
      _samples3 = fixture(:samples, from: t0, repeat: 100, series: series3, values: :linear)

      query_params = @query_params
      |> put_in([:tags], [%{key: tag2.key, value: tag2.value}, %{id: tag1.id}])
      |> put_in([:timestamp], t0 |> format_date!)

      conn = graphql_query conn, @query, query_params

      assert graphql_data(conn) == %{"series" => series_to_json(series2)
                                     |> put_in(["sample"], sample_to_json(samples2 |> Enum.at(0)))}
    end
  end
end
