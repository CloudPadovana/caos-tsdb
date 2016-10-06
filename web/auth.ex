######################################################################
#
# Filename: auth.ex
# Created: 2016-09-19T14:51:36+0200
# Time-stamp: <2016-10-06T10:47:21cest>
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

defmodule CaosApi.GuardianSerializer do
  @behaviour Guardian.Serializer

  def for_token(username) when is_binary(username), do: { :ok, username }
  def for_token(_), do: { :error, "Unknown resource type" }

  def from_token(username) when is_binary(username), do: { :ok, username }
  def from_token(_), do: { :error, "Unknown resource type" }
end

defmodule CaosApi.AuthErrorHandler do
  use CaosApi.Web, :controller

  def unauthenticated(conn, _params) do
    conn
    |> put_status(:unauthorized)
    |> render(CaosApi.ErrorView, "401.json")
  end
end
