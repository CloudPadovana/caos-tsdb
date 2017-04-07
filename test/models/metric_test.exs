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

defmodule CaosTsdb.MetricTest do
  use CaosTsdb.ModelCase

  alias CaosTsdb.Metric

  @metric %Metric{name: "a_name", type: "a type"}

  describe "valid changeset" do
    @valid_name @metric.name
    @valid_type "new #{@metric.type}"

    test "creation" do
      changeset = Metric.changeset(%Metric{}, %{name: @valid_name, type: @valid_type})
      assert changeset.valid?
    end

    test "change" do
      changeset = Metric.changeset(@metric, %{name: @valid_name, type: @valid_type})
      assert changeset.valid?
    end
  end

  describe "invalid changeset" do
    @valid_type @metric.type

    test "creation with missing name" do
      changeset = Metric.changeset(%Metric{}, %{type: @valid_type})
      refute changeset.valid?
    end

    test "creation with invalid name" do
      invalid_name = ".invalid"

      changeset = Metric.changeset(%Metric{}, %{name: invalid_name, type: @valid_type})
      refute changeset.valid?
    end

    test "change with new name" do
      invalid_name = "new #{@metric.name}"

      changeset = Metric.changeset(@metric, %{name: invalid_name, type: @valid_type})
      refute changeset.valid?
    end
  end
end
