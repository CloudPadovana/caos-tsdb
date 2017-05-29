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

defmodule CaosTsdb.Utils.Reducer do

  @spec reducer_for(atom) :: (number, tuple -> tuple)
  @spec acc_for(atom) :: tuple
  @spec value_for(tuple, atom) :: number

  def acc_for(:avg) do {0, 0} end
  def acc_for(:count) do {0} end
  def acc_for(:var) do {0, 0, 0} end
  def acc_for(:std) do acc_for(:var) end
  def acc_for(_) do {nil} end

  def reducer_for(:avg) do
    fn v, {sum, count} -> {sum + v, count + 1} end
  end

  def reducer_for(:count) do
    fn _v, {count} -> {count + 1} end
  end

  def reducer_for(:min) do
    fn
      v, {nil} -> {v}
      v, {min} -> {min(v, min)}
    end
  end

  def reducer_for(:max) do
    fn
      v, {nil} -> {v}
      v, {max} -> {max(v, max)}
    end
  end

  def reducer_for(:sum) do
    fn
      v, {nil} -> {v}
      v, {sum} -> {sum + v}
    end
  end

  def reducer_for(:var) do
    # Welford algorithm
    fn v, {n, mean, m2} ->
      n = n + 1
      delta = v - mean
      mean = mean + (delta / n)
      delta2 = v - mean
      m2 = m2 + (delta*delta2)

      {n, mean, m2}
    end
  end

  def reducer_for(:std) do
    reducer_for(:var)
  end

  def value_for({_sum, 0}, :avg) do nil end
  def value_for({sum, count}, :avg) do sum / count end
  def value_for({n, _mean, _m2}, :var) when n < 1 do nil end
  def value_for({n, _mean, _m2}, :var) when n < 2 do 0 end
  def value_for({n, _mean, m2}, :var) do m2 / n end
  def value_for({n, _mean, _m2}, :std) when n < 1 do nil end
  def value_for(acc, :std) do :math.sqrt(value_for(acc, :var)) end
  def value_for({value}, _) do value end
end
