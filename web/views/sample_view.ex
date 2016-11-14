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

defmodule CaosApi.SampleView do
  use CaosApi.Web, :view

  def render("show.json", %{samples: samples}) do
    %{data: render_many(samples, CaosApi.SampleView, "sample.json")}
  end

  def render("show.json", %{sample: sample}) do
    %{data: render_one(sample, CaosApi.SampleView, "sample.json")}
  end

  def render("sample.json", %{sample: sample}) do
    %{series_id: sample.series_id,
      timestamp: sample.timestamp,
      value: sample.value}
  end
end
