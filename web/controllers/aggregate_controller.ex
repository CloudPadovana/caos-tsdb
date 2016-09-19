######################################################################
#
# Filename: aggregate_controller.ex
# Created: 2016-09-15T09:48:46+0200
# Time-stamp: <2016-09-19T14:16:12cest>
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

defmodule CaosApi.AggregateController do
  use CaosApi.Web, :controller

  alias CaosApi.Sample
  alias CaosApi.Series

  plug :scrub_datetime, "from" when action in [:show]
  plug :scrub_datetime, "to" when action in [:show]

  @default_params %{"from" => Timex.DateTime.epoch,
                    "to" => Timex.DateTime.now,
                    "projects" => [],
                    "granularity" => 86400}

  def show(conn, params = %{"metric" => metric_name, "period" => period}) do
    %{"from" => from, "to" => to, "projects" => projects, "granularity" => granularity} = Map.merge(@default_params, params)

    ### NOTE: do not change "mytimestamp": pay attention to not to use SQL reserved names like "timestamp"
    aggregates = Sample
    |> join(:inner, [s], series in assoc(s, :series))
    |> where([s, series], series.metric_name == ^metric_name)
    |> where([s, series], series.period == ^period)
    |> where([s, series], series.project_id in ^projects)
    |> where([s], s.timestamp >= ^from)
    |> where([s], s.timestamp <= ^to)
    |> select([s, series], %{
                timestamp: fragment("CAST(DATE_ADD(?, INTERVAL (?*(1+((TO_SECONDS(?)-TO_SECONDS(?)) div ?))) SECOND) AS datetime) AS mytimestamp",
                  type(^from, :datetime),
                  type(^granularity, :integer),
                  s.timestamp,
                  type(^from, :datetime),
                  type(^granularity, :integer)),
                project_id: series.project_id,
                # aggregates
                avg: avg(s.value),
                count: count(s.value),
                min: min(s.value),
                max: max(s.value),
                std: fragment("stddev_pop(?)", s.value),
                var: fragment("var_pop(?)", s.value),
                sum: sum(s.value)})
    |> group_by([s, series], [series.project_id, fragment("mytimestamp")])
    |> order_by([s, series], [series.project_id, fragment("mytimestamp")])
    |> Repo.all
    |> Enum.map(fn(x)
      -> case Timex.Ecto.DateTime.load(x.timestamp) do
           {:ok, t} -> %{ x | timestamp: t }
         end
    end)

    render(conn, "show.json", %{aggregates: aggregates})
  end
end
