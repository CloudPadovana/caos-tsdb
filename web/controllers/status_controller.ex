######################################################################
#
# Filename: status_controller.ex
# Created: 2016-10-06T11:40:46+0200
# Time-stamp: <2016-10-06T13:13:01cest>
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

defmodule CaosApi.StatusController do
  use CaosApi.Web, :controller
  use Guardian.Phoenix.Controller

  @status "online"
  @version CaosApi.Version.version

  def index(conn, _params, _user, claims) do
    auth = case claims do
             { :ok, _ } -> "yes"
             { :error, _ } -> "no"
           end

    render(conn, "status.json", status: @status, version: @version, auth: auth)
  end
end

