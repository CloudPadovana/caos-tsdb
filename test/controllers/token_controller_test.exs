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

defmodule CaosTsdb.TokenControllerTest do
  use CaosTsdb.ConnCase

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "POST /token with wrong username", %{conn: conn} do
    conn = post conn, token_path(conn, :create), username: "invaliduser", password: "invalidpassword"
    assert json_response(conn, 400)["errors"] != %{}
  end

  test "POST /token with wrong password", %{conn: conn} do
    conn = post conn, token_path(conn, :create), username: "admin", password: "invalidpassword"
    assert json_response(conn, 400)["errors"] != %{}
  end

  test "POST /token with rigth credentials", %{conn: conn} do
    conn = post conn, token_path(conn, :create), username: "admin", password: "ADMIN_PASS"
    assert json_response(conn, 200)["data"]["token"] != {}
  end
end
