######################################################################
#
# Filename: aggregate_controller.ex
# Created: 2016-09-15T09:48:46+0200
# Time-stamp: <2016-11-04T10:06:36cet>
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
  plug :scrub_integer, "granularity" when action in [:show]
  plug :scrub_integer, "period" when action in [:show]

  @default_params %{"from" => epoch,
                    "to" => Timex.now,
                    "projects" => [],
                    "granularity" => 24*60*60}

  defp my_where(query, args = %{projects: []}) do
    query
    |> where([s, series], series.metric_name == ^args.metric_name)
    |> where([s, series], series.period == ^args.period)
    |> where([s], s.timestamp >= ^args.where_from)
    |> where([s], s.timestamp <= ^args.where_to)
  end

  defp my_where(query, args = %{projects: _}) do
    query
    |> my_where(%{args | projects: []})
    |> where([s, series], series.project_id in ^args.projects)
  end

  defp my_group_by(query, args = %{projects: []}) do
    query
    |> group_by([s, series], [fragment("myfrom")])
    |> order_by([s, series], [fragment("myfrom")])
  end

  defp my_group_by(query, args = %{projects: _}) do
    query
    |> group_by([s, series], [series.project_id, fragment("myfrom")])
    |> order_by([s, series], [series.project_id, fragment("myfrom")])
  end

  defp my_select(query, args) do
    query
    |> select([s, series], %{
                ### NOTE: do not change "myfrom": pay attention to not to use SQL reserved names like "timestamp, from"
                from: fragment("CAST(DATE_ADD(?, INTERVAL (?*((TO_SECONDS(?)-TO_SECONDS(?)) div ?)) SECOND) AS datetime) AS myfrom",
                  type(^args.from, :datetime),
                  type(^args.granularity, :integer),
                  datetime_add(s.timestamp, ^(-args.period), "second"),
                  type(^args.from, :datetime),
                  type(^args.granularity, :integer)),
                project_id: series.project_id,
                granularity: type(^args.granularity, :integer),
                # aggregates
                avg: avg(s.value),
                count: count(s.value),
                min: min(s.value),
                max: max(s.value),
                std: fragment("stddev_pop(?)", s.value),
                var: fragment("var_pop(?)", s.value),
                sum: sum(s.value)})
  end

  def show(conn, params = %{"metric" => metric_name, "period" => period}) do
    %{"from" => from,
      "to" => to,
      "projects" => projects,
      "granularity" => granularity
    } = Map.merge(@default_params, params)

    ### NOTE: where clauses have to be performed on raw fields, i.e. on the timestamp field
    where_from = from |> Timex.shift(seconds: period)
    where_to = to

    having_from = from
    having_to = to |> Timex.shift(seconds: -granularity)

    args = %{
      metric_name: metric_name,
      period: period,
      from: from,
      to: to,
      where_from: where_from,
      where_to: where_to,
      projects: projects,
      granularity: granularity
    }

    aggregates = Sample
    |> join(:inner, [s], series in assoc(s, :series))
    |> my_where(args)
    |> my_select(args)
    |> my_group_by(args)
    |> having([s], fragment("myfrom") >= ^having_from)
    |> having([s], fragment("myfrom") <= ^having_to)
    |> Repo.all
    |> Enum.map(fn(x)
      -> case Timex.Ecto.DateTime.load(x.from) do
           {:ok, t} -> %{ x | from: t }
         end
    end)

    render(conn, "show.json", %{aggregates: aggregates, projects: projects})
  end
end
