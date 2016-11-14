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

defmodule CaosApi.AggregateView do
  use CaosApi.Web, :view

  def render("show.json", %{aggregates: aggregates, projects: []}) do
    %{data: aggregates |> Enum.map(fn v -> render_one(v, CaosApi.AggregateView, "aggregate.json") end) }
  end

  def render("show.json", %{aggregates: aggregates, projects: _}) do
    %{data: aggregates |> Enum.group_by(fn x -> x.project_id end, fn v -> render_one(v, CaosApi.AggregateView, "aggregate.json") end) }
  end

  def render("aggregate.json", %{aggregate: aggregate}) do
    %{from: aggregate.from,
      to: aggregate.from |> Timex.shift(seconds: aggregate.granularity),
      timestamp: aggregate.from |> Timex.shift(seconds: aggregate.granularity),
      granularity: aggregate.granularity,
      avg: aggregate.avg,
      count: aggregate.count,
      min: aggregate.min,
      max: aggregate.max,
      std: aggregate.std,
      var: aggregate.var,
      sum: aggregate.sum}
  end
end

