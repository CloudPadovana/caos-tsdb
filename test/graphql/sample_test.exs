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

defmodule CaosTsdb.Graphql.SampleTest do
  use CaosTsdb.ConnCase

  import CaosTsdb.DateTime.Helpers

  setup %{conn: conn} do
    conn = conn
    |> put_req_header("accept", "application/json")
    |> put_valid_token()

    {:ok, conn: conn}
  end

  describe "get one sample" do
    @query """
    query($series: SeriesPrimary!, $timestamp: Datetime!) {
      sample: sample(series: $series, timestamp: $timestamp) {
        timestamp
        value
      }
    }
    """

    @a_timestamp fixture(:timestamp)
    @a_value 322.3
    @query_params %{series: %{id: nil},
                    timestamp: @a_timestamp |> format_date!}

    test "with valid arguments", %{conn: conn} do
      tag1 = fixture(:tag, key: "key1", value: "value1")
      tag2 = fixture(:tag, key: "key2", value: "value2")
      _tag3 = fixture(:tag, key: "key3", value: "value3")

      metric1 = fixture(:metric, name: "metric1")
      _metric2 = fixture(:metric, name: "metric2")

      series1 = fixture(:series, tags: [tag1, tag2], metric: metric1, period: 3600)
      _sample1 = fixture(:sample, series: series1, timestamp: @a_timestamp, value: @a_value)

      query_params = @query_params
      |> put_in([:series, :id], series1.id)
      conn = graphql_query conn, @query, query_params

      expected_json = %{"sample" => %{
                        "timestamp" => @a_timestamp |> format_date!,
                        "value" => @a_value}
                       }

      assert graphql_data(conn) == expected_json
    end
  end

  describe "get samples" do
    @query """
    query($series: SeriesPrimary!, $from: Datetime!, $to: Datetime!) {
      samples: samples(series: $series, from: $from, to: $to) {
        series {
          id
        }
        timestamp
        value
      }
    }
    """

    @a_timestamp fixture(:timestamp) |> Timex.shift(seconds: -100*3600)
    @a_value 322.3
    @query_params %{series: %{id: nil},
                    from: @a_timestamp |> format_date!,
                    to: nil}

    test "with valid arguments", %{conn: conn} do
      tag1 = fixture(:tag, key: "key1", value: "value1")
      tag2 = fixture(:tag, key: "key2", value: "value2")
      _tag3 = fixture(:tag, key: "key3", value: "value3")

      metric1 = fixture(:metric, name: "metric1")
      _metric2 = fixture(:metric, name: "metric2")

      series1 = fixture(:series, tags: [tag1, tag2], metric: metric1, period: 3600)
      samples = fixture(:samples, series: series1, from: @a_timestamp, repeat: 100)

      query_params = @query_params
      |> put_in([:series, :id], series1.id)
      |> put_in([:to], @a_timestamp |> Timex.shift(seconds: series1.period * 200) |> format_date!)
      new_conn = graphql_query conn, @query, query_params
      expected_json = %{"samples" => samples |> samples_to_json() }
      assert graphql_data(new_conn) == expected_json

      query_params = @query_params
      |> put_in([:series, :id], series1.id)
      |> put_in([:from], @a_timestamp |> Timex.shift(seconds: series1.period * 10) |> format_date!)
      new_conn = graphql_query conn, @query, query_params
      expected_json = %{"samples" => samples |> Enum.slice(10..100) |> samples_to_json() }
      assert graphql_data(new_conn) == expected_json

      query_params = @query_params
      |> put_in([:series, :id], series1.id)
      |> put_in([:from], @a_timestamp |> Timex.shift(seconds: series1.period * 10) |> format_date!)
      |> put_in([:to], @a_timestamp |> Timex.shift(seconds: series1.period * 20) |> format_date!)
      new_conn = graphql_query conn, @query, query_params
      expected_json = %{"samples" => samples |> Enum.slice(10..20) |> samples_to_json() }
      assert graphql_data(new_conn) == expected_json

      query_params = @query_params
      |> put_in([:series, :id], series1.id)
      |> put_in([:from], @a_timestamp |> Timex.shift(seconds: series1.period * 20) |> format_date!)
      |> put_in([:to], @a_timestamp |> Timex.shift(seconds: series1.period * 10) |> format_date!)
      new_conn = graphql_query conn, @query, query_params
      expected_json = %{"samples" => []}
      assert graphql_data(new_conn) == expected_json

      query_params = @query_params
      |> put_in([:series, :id], series1.id)
      |> put_in([:from], @a_timestamp |> Timex.shift(seconds: series1.period * 200) |> format_date!)
      |> put_in([:to], @a_timestamp |> Timex.shift(seconds: series1.period * 210) |> format_date!)
      new_conn = graphql_query conn, @query, query_params
      expected_json = %{"samples" => []}
      assert graphql_data(new_conn) == expected_json
    end
  end

  describe "create sample" do
    @query """
    mutation($series: SeriesPrimary!, $timestamp: Datetime!, $value: Float!, $overwrite: Boolean) {
      sample: create_sample(series: $series, timestamp: $timestamp, value: $value, overwrite: $overwrite) {
        timestamp
        value
      }
    }
    """

    @a_timestamp fixture(:timestamp)
    @a_value 322.3
    @query_params %{series: %{id: nil},
                    timestamp: @a_timestamp |> format_date!,
                    value: @a_value,
                    overwrite: false}

    test "when data is valid", %{conn: conn} do
      tag1 = fixture(:tag, key: "key1", value: "value1")
      tag2 = fixture(:tag, key: "key2", value: "value2")
      _tag3 = fixture(:tag, key: "key3", value: "value3")

      metric1 = fixture(:metric, name: "metric1")
      _metric2 = fixture(:metric, name: "metric2")

      series1 = fixture(:series, tags: [tag1, tag2], metric: metric1, period: 3600)

      query_params = @query_params
      |> put_in([:series, :id], series1.id)

      conn = graphql_query conn, @query, query_params
      expected_json = %{"sample" => %{
                        "timestamp" => @a_timestamp |> format_date!,
                        "value" => @a_value}
                       }
      assert graphql_data(conn) == expected_json
    end

    test "must fail if already exists", %{conn: conn} do
      tag1 = fixture(:tag, key: "key1", value: "value1")
      tag2 = fixture(:tag, key: "key2", value: "value2")
      _tag3 = fixture(:tag, key: "key3", value: "value3")

      metric1 = fixture(:metric, name: "metric1")
      _metric2 = fixture(:metric, name: "metric2")

      series1 = fixture(:series, tags: [tag1, tag2], metric: metric1, period: 3600)

      _sample1 = fixture(:sample, series: series1, timestamp: @a_timestamp, value: @a_value)

      query_params = @query_params
      |> put_in([:series, :id], series1.id)
      |> put_in([:value], @a_value + 1)
      conn = graphql_query conn, @query, query_params
      assert_graphql_errors(conn)
    end

    test "can be overwritten", %{conn: conn} do
      tag1 = fixture(:tag, key: "key1", value: "value1")
      tag2 = fixture(:tag, key: "key2", value: "value2")
      _tag3 = fixture(:tag, key: "key3", value: "value3")

      metric1 = fixture(:metric, name: "metric1")
      _metric2 = fixture(:metric, name: "metric2")

      series1 = fixture(:series, tags: [tag1, tag2], metric: metric1, period: 3600)

      _sample1 = fixture(:sample, series: series1, timestamp: @a_timestamp, value: @a_value)

      query_params = @query_params
      |> put_in([:series, :id], series1.id)
      |> put_in([:value], @a_value + 1)
      |> put_in([:overwrite], true)
      conn = graphql_query conn, @query, query_params
      expected_json = %{"sample" => %{
                        "timestamp" => @a_timestamp |> format_date!,
                        "value" => @a_value + 1}
                       }
      assert graphql_data(conn) == expected_json
    end
  end
end
