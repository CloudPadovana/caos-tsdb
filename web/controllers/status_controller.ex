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

defmodule CaosTsdb.StatusController do
  use CaosTsdb.Web, :controller
  use Guardian.Phoenix.Controller

  @status "online"
  @version CaosTsdb.Version.version

  def index(conn, _params, _user, claims) do
    auth = case claims do
             { :ok, _ } -> "yes"
             { :error, _ } -> "no"
           end

    api_version = conn.assigns[:version]
    render(conn, "status.json", status: @status, version: @version, auth: auth, api_version: api_version)
  end
end

