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

defmodule CaosTsdb.TokenController do
  use CaosTsdb.Web, :controller

  def create(conn, _body_params = %{"username" => username, "password" => password}) do
    cfg = Application.get_env(:caos_tsdb, Auth)
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
      |> render(CaosTsdb.ErrorView, "400.json")
    end
  end
end
