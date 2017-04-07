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

defmodule CaosTsdb.Graphql.TagTest do
  use CaosTsdb.ConnCase

  alias CaosTsdb.Tag
  alias CaosTsdb.TagMetadata
  import CaosTsdb.DateTime.Helpers

  setup %{conn: conn} do
    conn = conn
    |> put_req_header("accept", "application/json")
    |> put_valid_token()

    {:ok, conn: conn}
  end

  describe "failure on" do
    test "tag query without arguments", %{conn: conn} do
      query = """
      query {
        tag {
          id
          key
          value
        }
      }
      """

      conn = graphql_query conn, query
      assert json_response(conn, 200)["errors"] != []
    end
  end

  describe "get tag by id" do
    @query """
    query($id: ID!) {
      tag(id: $id) {
        id
        key
        value
      }
    }
    """

    test "should fail when there are no tags", %{conn: conn} do
      conn = graphql_query conn, @query, %{id: -1}
      assert json_response(conn, 200)["errors"] != []
    end

    test "when there is one tag", %{conn: conn} do
      tag1 = fixture(:tag)

      conn = graphql_query conn, @query, %{id: tag1.id}
      assert json_response(conn, 200)["data"] == %{"tag" => tag_to_json(tag1)}
    end

    test "when there are many tags", %{conn: conn} do
      _tag1 = fixture(:tag)
      tag2 = fixture(:tag, key: "a new key")
      _tag3 = fixture(:tag, key: "another new key")

      conn = graphql_query conn, @query, %{id: tag2.id}
      assert json_response(conn, 200)["data"] == %{"tag" => tag_to_json(tag2)}
    end
  end

  describe "get tag by key/value" do
    @query """
    query($key: String!, $value: String!) {
      tag(key: $key, value: $value) {
        id
        key
        value
      }
    }
    """

    test "should fail when there are no parameters", %{conn: conn} do
      conn = graphql_query conn, @query
      assert json_response(conn, 200)["errors"] != []
    end

    test "should fail when there are no tags", %{conn: conn} do
      conn = graphql_query conn, @query, %{key: "a key"}
      assert json_response(conn, 200)["errors"] != []
    end

    test "should fail when there are many matches", %{conn: conn} do
      _tag1 = fixture(:tag, key: "key1", value: "value1")
      _tag2 = fixture(:tag, key: "key1", value: "value2")
      _tag3 = fixture(:tag, key: "key1", value: "value3")

      conn = graphql_query conn, @query, %{key: "key1"}
      assert json_response(conn, 200)["errors"] != []
    end

    test "when there is one tag", %{conn: conn} do
      tag1 = fixture(:tag)

      conn = graphql_query conn, @query, %{key: tag1.key, value: tag1.value}
      assert json_response(conn, 200)["data"] == %{"tag" => tag_to_json(tag1)}
    end

    test "when there are many tags", %{conn: conn} do
      _tag1 = fixture(:tag)
      tag2 = fixture(:tag, key: "a new key")
      _tag3 = fixture(:tag, key: "another new key")

      conn = graphql_query conn, @query, %{key: tag2.key, value: tag2.value}
      assert json_response(conn, 200)["data"] == %{"tag" => tag_to_json(tag2)}
    end
  end

  describe "get tags' ids" do
    @query """
    query {
      tags {
        id
      }
    }
    """

    test "when there are no tags", %{conn: conn} do
      conn = graphql_query conn, @query
      assert json_response(conn, 200)["data"] == %{"tags" => []}
    end

    test "when there is one tag", %{conn: conn} do
      tag1 = fixture(:tag)

      conn = graphql_query conn, @query
      assert json_response(conn, 200)["data"] == %{"tags" => tags_to_json([tag1], [:id])}
    end

    test "when there are many tags", %{conn: conn} do
      tag1 = fixture(:tag)
      tag2 = fixture(:tag, key: "a new key")
      tag3 = fixture(:tag, key: "another new key")

      conn = graphql_query conn, @query
      assert json_response(conn, 200)["data"] == %{"tags" => tags_to_json([tag1, tag2, tag3], [:id])}
    end
  end

  describe "get tags" do
    @query """
    query {
      tags {
        id
        key
        value
      }
    }
    """

    test "when there are no tags", %{conn: conn} do
      conn = graphql_query conn, @query
      assert json_response(conn, 200)["data"] == %{"tags" => []}
    end

    test "when there is one tag", %{conn: conn} do
      tag1 = fixture(:tag)

      conn = graphql_query conn, @query
      assert json_response(conn, 200)["data"] == %{"tags" => tags_to_json([tag1])}
    end

    test "when there are many tags", %{conn: conn} do
      tag1 = fixture(:tag)
      tag2 = fixture(:tag, key: "a new key")
      tag3 = fixture(:tag, key: "another new key")

      conn = graphql_query conn, @query
      assert json_response(conn, 200)["data"] == %{"tags" => tags_to_json([tag1, tag2, tag3])}
    end
  end

  describe "get tags by key" do
    @query """
    query($key: String!) {
      tags(key: $key) {
        id
        key
        value
      }
    }
    """

    test "should fail when there are no parameters", %{conn: conn} do
      conn = graphql_query conn, @query
      assert json_response(conn, 200)["errors"] != []
    end

    test "should not fail when there are no tags", %{conn: conn} do
      conn = graphql_query conn, @query, %{key: "a key"}
      assert json_response(conn, 200)["data"] == %{"tags" => []}
    end

    test "when there is one match", %{conn: conn} do
      _tag11 = fixture(:tag, key: "key1", value: "value1")
      _tag12 = fixture(:tag, key: "key1", value: "value2")
      _tag13 = fixture(:tag, key: "key1", value: "value3")
      _tag21 = fixture(:tag, key: "key2", value: "value1")
      _tag22 = fixture(:tag, key: "key2", value: "value2")
      tag31 = fixture(:tag, key: "key3", value: "value1")

      conn = graphql_query conn, @query, %{key: "key3"}
      assert json_response(conn, 200)["data"] == %{"tags" => tags_to_json([tag31])}
    end

    test "when there are many matches", %{conn: conn} do
      _tag11 = fixture(:tag, key: "key1", value: "value1")
      _tag12 = fixture(:tag, key: "key1", value: "value2")
      _tag13 = fixture(:tag, key: "key1", value: "value3")
      tag21 = fixture(:tag, key: "key2", value: "value1")
      tag22 = fixture(:tag, key: "key2", value: "value2")
      _tag31 = fixture(:tag, key: "key3", value: "value1")

      conn = graphql_query conn, @query, %{key: "key2"}
      assert json_response(conn, 200)["data"] == %{"tags" => tags_to_json([tag21, tag22])}
    end
  end

  describe "get tag series" do
    @query """
    query {
      tags {
        id
        key
        value
        series {
          id
        }
      }
    }
    """

    test "when there is one series", %{conn: conn} do
      tag1 = fixture(:tag, key: "key1", value: "value1")
      tag2 = fixture(:tag, key: "key2", value: "value2")
      tag3 = fixture(:tag, key: "key3", value: "value3")

      metric1 = fixture(:metric, name: "metric1")
      _metric2 = fixture(:metric, name: "metric2")

      series2 = fixture(:series, tags: [tag1, tag2], metric: metric1, period: 3600)

      expected_json = %{"tags" => [
                         put_in(tag_to_json(tag1), ["series"], [%{"id" => "#{series2.id}"}]),
                         put_in(tag_to_json(tag2), ["series"], [%{"id" => "#{series2.id}"}]),
                         put_in(tag_to_json(tag3), ["series"], [])]}

      conn = graphql_query conn, @query
      assert json_response(conn, 200)["data"] == expected_json
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

      expected_json = %{"tags" => [
                         put_in(tag_to_json(tag1), ["series"], [
                               %{"id" => "#{series1.id}"},
                               %{"id" => "#{series2.id}"},
                               %{"id" => "#{series3.id}"}]),
                         put_in(tag_to_json(tag2), ["series"], [
                               %{"id" => "#{series2.id}"},
                               %{"id" => "#{series3.id}"}]),
                         put_in(tag_to_json(tag3), ["series"], [
                               %{"id" => "#{series3.id}"}])]}

      conn = graphql_query conn, @query
      assert json_response(conn, 200)["data"] == expected_json
    end
  end

  describe "get tag metadata" do
    @query """
    query($from: Datetime, $to: Datetime) {
      tags {
        id
        key
        value
        metadata(from: $from, to: $to) {
          timestamp
          metadata
        }
        last_metadata {
          timestamp
          metadata
        }
      }
    }
    """

    test "when there is no metadata", %{conn: conn} do
      tag1 = fixture(:tag, key: "key1", value: "value1")

      from = "2017-02-13T00:00:00Z"
      to = "2017-02-14T00:00:00Z"

      expected_json = %{"tags" => [
                         tag_to_json(tag1)
                         |> put_in(["metadata"], [])
                         |> put_in(["last_metadata"], tag_metadata_to_json(%TagMetadata{}))]}

      conn = graphql_query conn, @query, %{from: from, to: to}
      assert json_response(conn, 200)["data"] == expected_json
    end

    test "when there are many metadatas", %{conn: conn} do
      tag1 = fixture(:tag, key: "key1", value: "value1")
      tag2 = fixture(:tag, key: "key2", value: "value2")
      tag3 = fixture(:tag, key: "key3", value: "value3")

      t1 = "2017-02-14T00:00:00Z" |> parse_date!
      t2 = "2017-02-14T03:00:00Z" |> parse_date!
      t3 = "2017-02-14T06:00:00Z" |> parse_date!

      meta1 = fixture(:tag_metadata, tag: tag1, from: t1, repeat: 12)
      meta2 = fixture(:tag_metadata, tag: tag2, from: t2, repeat: 12)
      meta3 = fixture(:tag_metadata, tag: tag3, from: t3, repeat: 12)

      from = "2017-02-13T00:00:00Z"
      to = "2017-02-14T09:00:00Z"

      expected_json = %{"tags" => [
                         tag_to_json(tag1)
                         |> put_in(["metadata"], tag_metadatas_to_json(meta1 |> Enum.slice(0..9)))
                         |> put_in(["last_metadata"], tag_metadata_to_json(meta1 |> List.last)),

                         tag_to_json(tag2)
                         |> put_in(["metadata"], tag_metadatas_to_json(meta2 |> Enum.slice(0..6)))
                         |> put_in(["last_metadata"], tag_metadata_to_json(meta2 |> List.last)),

                         tag_to_json(tag3)
                         |> put_in(["metadata"], tag_metadatas_to_json(meta3 |> Enum.slice(0..3)))
                         |> put_in(["last_metadata"], tag_metadata_to_json(meta3 |> List.last))
                       ]}

      conn = graphql_query conn, @query, %{from: from, to: to}
      assert json_response(conn, 200)["data"] == expected_json
    end
  end

  describe "create tag" do
    @query """
    mutation($key: String!, $value: String!) {
      create_tag(key: $key, value: $value) {
        id
        key
        value
      }
    }
    """
    @valid_args %{key: "a.valid/name", value: "a/valid1/value"}
    @invalid_args %{key: "", value: "a value"}

    test "when data is valid", %{conn: conn} do
      conn = graphql_query conn, @query, @valid_args

      tag = json_response(conn, 200)["data"]["create_tag"] |> json_to_tag

      assert Map.take(tag, [:key, :value]) == @valid_args
      assert Repo.get_by(Tag, @valid_args)
    end

    test "should fail when data is invalid", %{conn: conn} do
      conn = graphql_query conn, @query, @invalid_args
      assert json_response(conn, 200)["errors"] != []
    end

    test "returns already existent tag", %{conn: conn} do
      tag1 = fixture(:tag, key: @valid_args.key, value: @valid_args.value)
      conn = graphql_query conn, @query, @valid_args

      assert json_response(conn, 200)["data"] == %{"create_tag" => tag_to_json(tag1)}
    end
  end
end
