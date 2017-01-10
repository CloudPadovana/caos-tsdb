################################################################################
#
# caos-tsdb - CAOS Time-Series DB
#
# Copyright © 2017 INFN - Istituto Nazionale di Fisica Nucleare (Italy)
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

defmodule CaosTsdb.EndpointTest do
  use CaosTsdb.ConnCase

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "request token" do
    @api_endpoint "/api/v1/token"

    @valid_username Application.get_env(:caos_tsdb, Auth)[:identity][:username]
    @valid_password Application.get_env(:caos_tsdb, Auth)[:identity][:password]
    @invalid_username "invaliduser"
    @invalid_password "invalidpass"

    test "with wrong username", %{conn: conn} do
      conn = post conn, @api_endpoint, username: @invalid_username, password: @valid_password
      assert json_response(conn, 400)["errors"] != %{}
    end

    test "with wrong password", %{conn: conn} do
      conn = post conn, @api_endpoint, username: @valid_username, password: @invalid_password
      assert json_response(conn, 400)["errors"] != %{}
    end

    test "with rigth credentials", %{conn: conn} do
      conn = post conn, @api_endpoint, username: @valid_username, password: @valid_password
      assert json_response(conn, 200)["data"]["token"] != {}
    end
  end

  describe "request status" do
    @api_endpoint "/api/v1/status"

    @valid_token fixture(:token)

    @expected_status %{"status" => "online",
                       "auth" => nil,
                       "api_version" => "v1",
                       "version" => CaosTsdb.Version.version}

    test "without token", %{conn: conn} do
      conn = get conn, @api_endpoint
      assert json_response(conn, 200)["data"] == %{ @expected_status | "auth" => "no" }
    end

    test "with valid token", %{conn: conn} do
      conn = conn
      |> put_req_header("authorization", "Bearer #{@valid_token}")
      |> get(@api_endpoint)
      assert json_response(conn, 200)["data"] == %{ @expected_status | "auth" => "yes" }
    end

    test "with invalid token", %{conn: conn} do
      ttl = Application.get_env(:guardian, Guardian)[:ttl] |> elem(0)
      iat = Timex.now()
      |> Timex.shift(seconds: -ttl)
      |> Timex.shift(seconds: -1)
      |> Timex.to_unix()

      invalid_token = fixture(:token, claims: %{"iat" => iat})

      conn = conn
      |> put_req_header("authorization", "Bearer #{invalid_token}")
      |> get(@api_endpoint)
      assert json_response(conn, 200)["data"] == %{ @expected_status | "auth" => "no" }
    end
  end
end
