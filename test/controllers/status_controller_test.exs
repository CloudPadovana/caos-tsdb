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

defmodule CaosTsdb.StatusControllerTest do
  use CaosTsdb.ConnCase
  use Timex

  @status %{"status" => "online",
            "auth" => "no",
            "api_version" => "v1",
            "version" => CaosTsdb.Version.version}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "GET /api/status", %{conn: conn} do
    conn = get conn, status_path(conn, :index)
    assert json_response(conn, 200)["data"] == @status
  end

  test "GET /api/status with valid token", %{conn: conn} do
    conn = put_valid_token(conn)
    conn = get conn, status_path(conn, :index)
    assert json_response(conn, 200)["data"] == %{ @status | "auth" => "yes" }
  end

  test "GET /api/status with invalid token", %{conn: conn} do
    iat = Timex.now |> Timex.shift(days: -10) |> Timex.to_unix
    jwt = fixture(:token, username: "some user", claims: %{"iat" => iat})

    conn = put_token(conn, jwt)
    conn = get conn, status_path(conn, :index)
    assert json_response(conn, 200)["data"] == %{ @status | "auth" => "no" }
  end

end

