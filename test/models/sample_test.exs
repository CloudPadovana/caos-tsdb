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

defmodule CaosTsdb.SampleTest do
  use CaosTsdb.ModelCase

  alias CaosTsdb.Sample
  alias CaosTsdb.Series
  use Timex
  @series %Series{id: 1,
                  metric_name: "a name",
                  period: 3600,
                  ttl: 500}

  @valid_attrs %{series_id: @series.id,
                 timestamp: Timex.now,
                 value: 322.3}
  @sample struct(Sample, @valid_attrs)


  test "changeset with valid attributes" do
    changeset = Sample.changeset(%Sample{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Sample.changeset(%Sample{}, %{series_id: 22})
    refute changeset.valid?
  end

  test "changeset with valid change" do
    changeset = Sample.changeset(@sample, %{})
    assert changeset.valid?
  end

  test "changeset with invalid change" do
    changeset = Sample.changeset(@sample, %{value: 24.3})
    refute changeset.valid?
  end
end
