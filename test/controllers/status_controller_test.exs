######################################################################
#
# Filename: status_controller_test.exs
# Created: 2016-10-06T11:32:51+0200
# Time-stamp: <2016-10-06T13:11:44cest>
# Author: Fabrizio Chiarello <fabrizio.chiarello@pd.infn.it>
#
# Copyright © 2016 by Fabrizio Chiarello
#
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
######################################################################

defmodule CaosApi.StatusControllerTest do
  use CaosApi.ConnCase
  use Timex

  @status %{"status" => "online",
            "auth" => "no",
            "version" => CaosApi.Version.version}

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
    iat = Timex.DateTime.now |> Timex.shift(days: -10) |> Timex.to_unix
    jwt = fixture(:token, username: "some user", claims: %{"iat" => iat})

    conn = put_token(conn, jwt)
    conn = get conn, status_path(conn, :index)
    assert json_response(conn, 200)["data"] == %{ @status | "auth" => "no" }
  end

end

