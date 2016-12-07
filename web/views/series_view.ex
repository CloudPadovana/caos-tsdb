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

defmodule CaosTsdb.SeriesView do
  use CaosTsdb.Web, :view

  def render("index.json", %{series: series}) do
    %{data: render_many(series, CaosTsdb.SeriesView, "series.json")}
  end

  def render("show.json", %{series: series}) do
    %{data: render_one(series, CaosTsdb.SeriesView, "series.json")}
  end

  def render("series.json", %{series: series}) do
    %{id: series.id,
      project_id: series.project_id,
      metric_name: series.metric_name,
      period: series.period,
      ttl: series.ttl,
      last_timestamp: series.last_timestamp}
  end

  def render("grid.json", %{grid: grid}) do
    %{data: %{grid: grid}}
  end
end
