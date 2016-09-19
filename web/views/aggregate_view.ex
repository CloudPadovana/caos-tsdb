######################################################################
#
# Filename: aggregate_view.ex
# Created: 2016-09-15T10:03:58+0200
# Time-stamp: <2016-09-19T10:23:07cest>
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

defmodule CaosApi.AggregateView do
  use CaosApi.Web, :view

  def render("show.json", %{aggregates: aggregates}) do
    %{data: aggregates |> Enum.group_by(fn x -> x.project_id end, fn v -> render_one(v, CaosApi.AggregateView, "aggregate.json") end) }
  end

  def render("aggregate.json", %{aggregate: aggregate}) do
    %{timestamp: aggregate.timestamp,
      project_id: aggregate.project_id,
      avg: aggregate.avg,
      count: aggregate.count,
      min: aggregate.min,
      max: aggregate.max,
      std: aggregate.std,
      var: aggregate.var,
      sum: aggregate.sum}
  end
end

