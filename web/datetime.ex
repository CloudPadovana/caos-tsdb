################################################################################
#
# caos-api - CAOS backend
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

defmodule CaosApi.DateTime.Helpers do
  use Timex

  @epoch DateTime.from_unix!(0)
  def epoch() do
    @epoch
  end

  def parse_date(date) do
    date
    |> Timex.parse("%FT%TZ", :strftime)
  end

  def parse_date!(date) do
    date
    |> Timex.parse!("%FT%TZ", :strftime)
  end

  def format_date(date) do
    date
    |> Timex.format("%FT%TZ", :strftime)
  end

  def format_date!(date) do
    date
    |> Timex.format!("%FT%TZ", :strftime)
  end

  @spec scrub_datetime(Plug.Conn.t, String.t) :: Plug.Conn.t
  def scrub_datetime(conn, key) when is_binary(key) do
    case Map.fetch(conn.params, key) do
      {:ok, value} ->
        case parse_date(value) do
          {:ok, datetime} ->
            %{conn | params: %{conn.params | key => datetime}}
          {:error, _} ->
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
