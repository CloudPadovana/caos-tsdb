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

defmodule CaosTsdb.MetricTest do
  use CaosTsdb.ModelCase

  alias CaosTsdb.Metric

  @metric %Metric{name: "a name", type: "a type"}
  @valid_attrs %{name: "a name", type: "a new type"}

  test "changeset with valid creation" do
    changeset = Metric.changeset(%Metric{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid creation" do
    changeset = Metric.changeset(%Metric{}, %{type: "a type"})
    refute changeset.valid?
  end

  test "changeset with valid change" do
    changeset = Metric.changeset(@metric, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid change" do
    changeset = Metric.changeset(@metric, %{name: "a new name", type: "a type"})
    refute changeset.valid?
  end
end
