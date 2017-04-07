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

defmodule CaosTsdb.Graphql.MetricTest do
  use CaosTsdb.ConnCase

  alias CaosTsdb.Metric

  setup %{conn: conn} do
    conn = conn
    |> put_req_header("accept", "application/json")
    |> put_valid_token()

    {:ok, conn: conn}
  end

  describe "failure on" do
    test "metric query without arguments", %{conn: conn} do
      query = """
      query {
        metric {
          name
          type
        }
      }
      """

      conn = graphql_query conn, query
      assert json_response(conn, 200)["errors"] != []
    end
  end

  describe "get metric by name" do
    @query """
    query($name: String!) {
      metric(name: $name) {
        name
        type
      }
    }
    """

    test "should fail when there are no parameters", %{conn: conn} do
      conn = graphql_query conn, @query
      assert json_response(conn, 200)["errors"] != []
    end

    test "should fail when there are no metrics", %{conn: conn} do
      conn = graphql_query conn, @query, %{name: "metric1"}
      assert json_response(conn, 200)["errors"] != []
    end

    test "when there is one metric", %{conn: conn} do
      metric1 = fixture(:metric)

      conn = graphql_query conn, @query, %{name: metric1.name}
      assert json_response(conn, 200)["data"] == %{"metric" => metric_to_json(metric1)}
    end

    test "when there are many metrics", %{conn: conn} do
      _metric1 = fixture(:metric, name: "metric1")
      metric2 = fixture(:metric, name: "metric2")
      _metric3 = fixture(:metric, name: "metric3")

      conn = graphql_query conn, @query, %{name: metric2.name}
      assert json_response(conn, 200)["data"] == %{"metric" => metric_to_json(metric2)}
    end
  end

  describe "get metrics' names" do
    @query """
    query {
      metrics {
        name
      }
    }
    """

    test "when there are no metrics", %{conn: conn} do
      conn = graphql_query conn, @query
      assert json_response(conn, 200)["data"] == %{"metrics" => []}
    end

    test "when there is one metric", %{conn: conn} do
      metric1 = fixture(:metric)

      conn = graphql_query conn, @query
      assert json_response(conn, 200)["data"] == %{"metrics" => metrics_to_json([metric1], [:name])}
    end

    test "when there are many metrics", %{conn: conn} do
      metric1 = fixture(:metric, name: "metric1")
      metric2 = fixture(:metric, name: "metric2")
      metric3 = fixture(:metric, name: "metric3")

      conn = graphql_query conn, @query
      assert json_response(conn, 200)["data"] == %{"metrics" => metrics_to_json([metric1, metric2, metric3], [:name])}
    end
  end

  describe "get metrics" do
    @query """
    query {
      metrics {
        name
        type
      }
    }
    """

    test "when there are no metrics", %{conn: conn} do
      conn = graphql_query conn, @query
      assert json_response(conn, 200)["data"] == %{"metrics" => []}
    end

    test "when there is one metric", %{conn: conn} do
      metric1 = fixture(:metric)

      conn = graphql_query conn, @query
      assert json_response(conn, 200)["data"] == %{"metrics" => metrics_to_json([metric1])}
    end

    test "when there are many metrics", %{conn: conn} do
      metric1 = fixture(:metric, name: "metric1")
      metric2 = fixture(:metric, name: "metric2")
      metric3 = fixture(:metric, name: "metric3")

      conn = graphql_query conn, @query
      assert json_response(conn, 200)["data"] == %{"metrics" => metrics_to_json([metric1, metric2, metric3])}
    end
  end

  describe "get metrics by type" do
    @query """
    query($type: String!) {
      metrics(type: $type) {
        name
        type
      }
    }
    """

    test "should fail when there are no parameters", %{conn: conn} do
      conn = graphql_query conn, @query
      assert json_response(conn, 200)["errors"] != []
    end

    test "should not fail when there are no metrics", %{conn: conn} do
      conn = graphql_query conn, @query, %{type: "a type"}
      assert json_response(conn, 200)["data"] == %{"metrics" => []}
    end

    test "when there is one match", %{conn: conn} do
      _metric11 = fixture(:metric, name: "metric1", type: "type1")
      _metric21 = fixture(:metric, name: "metric2", type: "type1")
      _metric31 = fixture(:metric, name: "metric3", type: "type1")
      _metric42 = fixture(:metric, name: "metric4", type: "type2")
      _metric52 = fixture(:metric, name: "metric5", type: "type2")
      metric63 = fixture(:metric, name: "metric6", type: "type3")

      conn = graphql_query conn, @query, %{type: "type3"}
      assert json_response(conn, 200)["data"] == %{"metrics" => metrics_to_json([metric63])}
    end

    test "when there are many matches", %{conn: conn} do
      _metric11 = fixture(:metric, name: "metric1", type: "type1")
      _metric21 = fixture(:metric, name: "metric2", type: "type1")
      _metric31 = fixture(:metric, name: "metric3", type: "type1")
      metric42 = fixture(:metric, name: "metric4", type: "type2")
      metric52 = fixture(:metric, name: "metric5", type: "type2")
      _metric63 = fixture(:metric, name: "metric6", type: "type3")

      conn = graphql_query conn, @query, %{type: "type2"}
      assert json_response(conn, 200)["data"] == %{"metrics" => metrics_to_json([metric42, metric52])}
    end
  end

  describe "get metric series" do
    @query """
    query {
      metrics {
        name
        type
        series {
          id
        }
      }
    }
    """

    test "when there is one series", %{conn: conn} do
      tag1 = fixture(:tag, key: "key1", value: "value1")
      tag2 = fixture(:tag, key: "key2", value: "value2")
      _tag3 = fixture(:tag, key: "key3", value: "value3")

      metric1 = fixture(:metric, name: "metric1")
      metric2 = fixture(:metric, name: "metric2")

      series2 = fixture(:series, tags: [tag1, tag2], metric: metric1, period: 3600)

      expected_json = %{"metrics" => [
                         put_in(metric_to_json(metric1), ["series"], [%{"id" => "#{series2.id}"}]),
                         put_in(metric_to_json(metric2), ["series"], [])]}

      conn = graphql_query conn, @query
      assert json_response(conn, 200)["data"] == expected_json
    end

    test "when there are many series", %{conn: conn} do
      tag1 = fixture(:tag, key: "key1", value: "value1")
      tag2 = fixture(:tag, key: "key2", value: "value2")
      tag3 = fixture(:tag, key: "key3", value: "value3")

      metric1 = fixture(:metric, name: "metric1")
      metric2 = fixture(:metric, name: "metric2")

      series1 = fixture(:series, tags: [tag1], metric: metric1, period: 3600)
      series2 = fixture(:series, tags: [tag1, tag2], metric: metric1, period: 3600)
      series3 = fixture(:series, tags: [tag1, tag2, tag3], metric: metric1, period: 86400)

      expected_json = %{"metrics" => [
                         put_in(metric_to_json(metric1), ["series"], [
                               %{"id" => "#{series1.id}"},
                               %{"id" => "#{series2.id}"},
                               %{"id" => "#{series3.id}"}]),
                         put_in(metric_to_json(metric2), ["series"], [])]}

      conn = graphql_query conn, @query
      assert json_response(conn, 200)["data"] == expected_json
    end
  end

  describe "create metric" do
    @query """
    mutation($name: String!, $type: String) {
      create_metric(name: $name, type: $type) {
        name
        type
      }
    }
    """
    @valid_args %{name: "a/valid.name", type: "a type"}
    @invalid_args %{name: "", type: "a type"}

    test "when data is valid", %{conn: conn} do
      conn = graphql_query conn, @query, @valid_args

      metric = json_response(conn, 200)["data"]["create_metric"] |> json_to_metric

      assert Map.take(metric, [:name, :type]) == @valid_args
      assert Repo.get_by(Metric, @valid_args)
    end

    test "should fail when data is invalid", %{conn: conn} do
      conn = graphql_query conn, @query, @invalid_args
      assert json_response(conn, 200)["errors"] != []
    end

    test "returns already existent metric", %{conn: conn} do
      metric1 = fixture(:metric, name: @valid_args.name, type: @valid_args.type)
      conn = graphql_query conn, @query, @valid_args

      assert json_response(conn, 200)["data"] == %{"create_metric" => metric_to_json(metric1)}
    end
  end
end
