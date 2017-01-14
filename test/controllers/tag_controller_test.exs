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

defmodule CaosTsdb.TagControllerTest do
  use CaosTsdb.ConnCase

  alias CaosTsdb.Tag

  @valid_attrs %{key: "a name",
                 value: "a value",
                 extra: %{"a key" => "a value",
                          "another key" => "another value"}}
  @invalid_attrs %{key: "", value: "a value"}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
    {:ok, conn: put_valid_token(conn)}
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, tag_path(conn, :index)
    assert json_response(conn, 200)["data"] == []
  end

  test "shows chosen resource", %{conn: conn} do
    tag = fixture(:tag)
    conn = get conn, tag_path(conn, :show, tag.id)
    assert json_response(conn, 200)["data"] == %{"id" => tag.id,
                                                 "key" => tag.key,
                                                 "value" => tag.value,
                                                 "extra" => tag.extra}
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    conn = get conn, tag_path(conn, :show, -1)
    assert json_response(conn, 404)["errors"] != %{}
  end

  test "creates and renders resource when data is valid", %{conn: conn} do
    conn = post conn, tag_path(conn, :create), tag: @valid_attrs
    assert json_response(conn, 201)["data"]["id"]
    assert Repo.get_by(Tag, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, tag_path(conn, :create), tag: @invalid_attrs
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "does not create resource and renders errors when data is not unique", %{conn: conn} do
    conn1 = post conn, tag_path(conn, :create), tag: @valid_attrs
    assert json_response(conn1, 201)["data"]["id"]

    conn2 = post conn, tag_path(conn, :create), tag: @valid_attrs
    assert json_response(conn2, 422)["errors"] != %{}
  end

  test "updates and renders chosen resource when data is valid", %{conn: conn} do
    tag = fixture(:tag)
    params = %{key: tag.key, value: tag.value, extra: %{"some new key" => "a new value"}}

    conn = put conn, tag_path(conn, :update, tag), tag: params
    assert json_response(conn, 200)["data"]["id"]
    assert json_response(conn, 200)["data"]["extra"] == params.extra
    assert Repo.get_by(Tag, params)
  end

  test "does not update chosen resource and renders errors when data is not the same", %{conn: conn} do
    tag = fixture(:tag)

    conn1 = put conn, tag_path(conn, :update, tag), tag: %{key: "a new name"}
    assert json_response(conn1, 422)["errors"] != %{}

    conn2 = put conn, tag_path(conn, :update, tag), tag: %{value: "a new value"}
    assert json_response(conn2, 422)["errors"] != %{}
  end
end
