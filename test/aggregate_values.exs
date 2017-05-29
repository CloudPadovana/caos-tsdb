################################################################################
#
# caos-tsdb - CAOS Time-Series DB
#
# Copyright © 2017 INFN - Istituto Nazionale di Fisica Nucleare (Italy)
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

defmodule CaosTsdb.AggregateValuesTest do
  use ExUnit.Case

  import CaosTsdb.Utils.AggregateValues

  test "aggregate_values on empty list" do
    values = []

    assert aggregate_values(values, :avg) == nil
    assert aggregate_values(values, :count) == 0
    assert aggregate_values(values, :min) == nil
    assert aggregate_values(values, :max) == nil
    assert aggregate_values(values, :sum) == nil
    assert aggregate_values(values, :var) == nil
    assert aggregate_values(values, :std) == nil
  end

  test "aggregate_values on list with one item" do
    values = [4]

    assert aggregate_values(values, :avg) == 4
    assert aggregate_values(values, :count) == 1
    assert aggregate_values(values, :min) == 4
    assert aggregate_values(values, :max) == 4
    assert aggregate_values(values, :sum) == 4
    assert aggregate_values(values, :var) == 0
    assert aggregate_values(values, :std) == 0
  end

  test "aggregate_values on list with one negative item" do
    values = [-4]

    assert aggregate_values(values, :avg) == -4
    assert aggregate_values(values, :count) == 1
    assert aggregate_values(values, :min) == -4
    assert aggregate_values(values, :max) == -4
    assert aggregate_values(values, :sum) == -4
    assert aggregate_values(values, :var) == 0
    assert aggregate_values(values, :std) == 0
  end

  test "aggregate_values on list with many positive items" do
    values = [4, 2, 3, 7, 13]

    assert aggregate_values(values, :avg) == 5.8
    assert aggregate_values(values, :count) == 5
    assert aggregate_values(values, :min) == 2
    assert aggregate_values(values, :max) == 13
    assert aggregate_values(values, :sum) == 29
    assert aggregate_values(values, :var) == 15.76
    assert aggregate_values(values, :std) |> Float.round(5) == 3.96989
  end

  test "aggregate_values on list with many items" do
    values = [-4, 2, 0, 3, -7, -13]

    assert aggregate_values(values, :avg) |> Float.round(5) == -3.16667
    assert aggregate_values(values, :count) == 6
    assert aggregate_values(values, :min) == -13
    assert aggregate_values(values, :max) == 3
    assert aggregate_values(values, :sum) == -19
    assert aggregate_values(values, :var) |> Float.round(5) == 31.13889
    assert aggregate_values(values, :std) |> Float.round(5) == 5.58022
  end
end
