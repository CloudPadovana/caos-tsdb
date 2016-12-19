################################################################################
#
# caos-tsdb - CAOS Time-Series DB
#
# Copyright © 2016, 2017 INFN - Istituto Nazionale di Fisica Nucleare (Italy)
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

defmodule CaosTsdb.AggregateView do
  use CaosTsdb.Web, :view

  def render("show.json", %{aggregates: aggregates, tags: []}) do
    %{data: aggregates |> Enum.map(fn v -> render_one(v, CaosTsdb.AggregateView, "aggregate.json") end) }
  end

  def render("show.json", %{aggregates: aggregates, tags: _}) do
    %{data: aggregates |> Enum.group_by(fn x -> "#{x.tag_id}" end, fn v -> render_one(v, CaosTsdb.AggregateView, "aggregate.json") end) }
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

