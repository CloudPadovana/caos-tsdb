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

defmodule CaosTsdb.GuardianSerializer do
  @behaviour Guardian.Serializer

  def for_token(username) when is_binary(username), do: { :ok, username }
  def for_token(_), do: { :error, "Unknown resource type" }

  def from_token(username) when is_binary(username), do: { :ok, username }
  def from_token(_), do: { :error, "Unknown resource type" }
end

defmodule CaosTsdb.AuthErrorHandler do
  use CaosTsdb.Web, :controller

  def unauthenticated(conn, _params) do
    conn
    |> put_status(:unauthorized)
    |> render(CaosTsdb.ErrorView, "401.json")
  end
end
