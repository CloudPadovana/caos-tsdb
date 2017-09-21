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

  import CaosTsdb.DateTime.Helpers

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
                       "last_sample_timestamp" => nil,
                       "api_version" => "v1.2",
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

    test "with last sample timestamp", %{conn: conn} do
      t0 = "2017-01-16T16:00:00Z"
      sample = fixture(:samples, from: t0 |> parse_date!)

      conn1 = conn
      |> get(@api_endpoint)

      assert json_response(conn1, 200)["data"]["last_sample_timestamp"] == t0

      conn2 = conn
      |> put_req_header("authorization", "Bearer #{@valid_token}")
      |> get(@api_endpoint)

      assert json_response(conn2, 200)["data"]["last_sample_timestamp"] == t0
    end
  end

  describe "logging" do
    import ExUnit.CaptureLog
    require Logger

    setup %{conn: conn} do
      conn = conn
      |> put_valid_token()

      level = Logger.level
      Logger.configure level: :info
      on_exit fn -> Logger.configure level: level end

      {:ok, conn: conn}
    end

    test "assert capture_log on Logger.error" do
      str = Base.hex_encode32(:crypto.strong_rand_bytes(20), case: :lower)

      assert capture_log(fn -> Logger.error str end) =~ str
    end

    test "route not found logs a request_id", %{conn: conn} do
      log = capture_log(fn ->
        assert_error_sent :not_found, fn ->
          get conn, "/not-found"
        end
      end)

      assert log =~ "request_id="
      assert log =~ "[error]"
      assert log =~ "ERROR: ** (Phoenix.Router.NoRouteError) no route found for GET /not-found"
      assert log =~ "REASON: %Phoenix.Router.NoRouteError{"
    end

    test "graphql errors generally do not raise", %{conn: conn} do
      query = "mutation { FailingThing(type: WITHOUT_MESSAGE) { name } "

      log = capture_log(fn ->
        graphql_query conn, query
      end)

      assert log =~ "request_id="
      refute log =~ "[error]"
      refute log =~ "ERROR"
      refute log =~ "REASON"
    end

    test "graphql logs query parameters", %{conn: conn} do
      query = "query { metrics { name } }"

      log = capture_log(fn ->
        graphql_query conn, query
      end)

      assert log =~ "request_id="
      assert log =~ "[info]"
      refute log =~ "ERROR"
      assert log =~ "POST /api/v1/graphql"
      assert log =~ "application=absinthe"
      assert log =~ "ABSINTHE"
      assert log =~ query
    end
  end
end
