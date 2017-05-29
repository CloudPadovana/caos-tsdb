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

defmodule CaosTsdb.Utils.AggregateValues do

  alias CaosTsdb.Utils.Reducer

  @spec aggregate_values(Enumerable.t, atom) :: number
  def aggregate_values(values, function) do
    acc = Reducer.acc_for(function)
    reducer = Reducer.reducer_for(function)

    values
    |> Enum.reduce(acc, reducer)
    |> Reducer.value_for(function)
  end
end
