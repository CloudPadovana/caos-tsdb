######################################################################
#
# Filename: token_controller_test.exs
# Created: 2016-09-19T14:57:49+0200
# Time-stamp: <2016-11-04T11:32:49cet>
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

defmodule CaosApi.TokenControllerTest do
  use CaosApi.ConnCase

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
