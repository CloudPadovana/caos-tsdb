######################################################################
#
# Filename: token_controller.ex
# Created: 2016-10-04T14:58:40+0200
# Time-stamp: <2016-10-05T20:02:40cest>
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

defmodule CaosApi.TokenController do
  use CaosApi.Web, :controller

  def show(conn, _params = %{"username" => username, "password" => password}) do
    cfg = Application.get_env(:caos_api, Auth)
    identity = Keyword.get(cfg, :identity)

    with {:ok, ^username} <- Keyword.fetch(identity, :username),
         {:ok, ^password} <- Keyword.fetch(identity, :password),
         {:ok, jwt, _claims} <- Guardian.encode_and_sign(username, :access) do
      conn
      |> put_resp_header("authorization", "Bearer #{jwt}")
      |> render("show.json", jwt: jwt)
    else
      _ -> conn
      |> put_status(:bad_request)
      |> render(CaosApi.ErrorView, "400.json")
    end
  end
end
