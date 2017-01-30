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

  setup %{conn: conn} do
    conn = conn
    |> put_req_header("accept", "application/json")
    |> put_valid_token()

    {:ok, conn: conn}
  end

  defp tag_to_json(tag, fields \\ [:id, :key, :value]) do
    %{
      id: %{"id" => "#{tag.id}"},
      key: %{"key" => tag.key},
      value: %{"value" => tag.value}
    } |> Map.take(fields)
    |> Map.values
    |> Enum.reduce(%{}, fn (map, acc) -> Map.merge(acc, map) end)
  end
  defp tags_to_json(tags, fields \\ [:id, :key, :value]) do
    tags
    |> Enum.map(&(tag_to_json(&1, fields)))
  end

  defp json_to_tag(json) do
    %{
      id: json["id"],
      key: json["key"],
      value: json["value"]
    }
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
    @valid_args %{key: "a name", value: "a value"}
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
