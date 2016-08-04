######################################################################
#
# Filename: datetime.ex
# Created: 2016-07-11T11:22:26+0200
# Time-stamp: <2016-08-04T12:57:52cest>
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

defmodule CaosApi.DateTime.Helpers do
  use Timex

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

  defimpl Poison.Encoder, for: Timex.DateTime do
    def encode(d, _options) do
      fmt = Timex.format!(d, "%FT%TZ", :strftime)
      "\"#{fmt}\""
    end
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
