######################################################################
#
# Filename: helpers.ex
# Created: 2016-09-27T17:03:09+0200
# Time-stamp: <2016-09-27T17:10:42cest>
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

defmodule CaosApi.Helpers do
  @spec scrub_integer(Plug.Conn.t, String.t) :: Plug.Conn.t
  def scrub_integer(conn, key) when is_binary(key) do
    case Map.fetch(conn.params, key) do
      {:ok, value} ->
        case Integer.parse(value) do
          {i, ""} ->
            %{conn | params: %{conn.params | key => i}}
          _ ->
            conn
            |> Plug.Conn.put_status(:bad_request)
            |> Phoenix.Controller.render(CaosApi.ErrorView, "400.json")
            |> Plug.Conn.halt
        end
      :error ->
        conn
    end
  end
end

