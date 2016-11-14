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

defmodule CaosApi.SeriesTest do
  use CaosApi.ModelCase

  alias CaosApi.Project
  alias CaosApi.Metric
  alias CaosApi.Series

  @project %Project{id: "an id", name: "a name"}
  @metric %Metric{name: "a name", type: "a type"}

  @valid_attrs %{id: 1,
                 project_id: @project.id,
                 metric_name: @metric.name,
                 period: 3600,
                 ttl: 500}
  @series struct(Series, @valid_attrs)

  test "changeset with valid creation" do
    changeset = Series.changeset(%Series{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid creation" do
    changeset = Series.changeset(%Series{}, %{metric_name: "a new name"})
    refute changeset.valid?
  end

  test "changeset with valid change" do
    changeset = Series.changeset(@series, %{ttl: 200})
    assert changeset.valid?
  end

  test "changeset with invalid change" do
    changeset = Series.changeset(@series, %{project_id: "a new id"})
    refute changeset.valid?
  end
end
