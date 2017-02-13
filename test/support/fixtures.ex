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

defmodule CaosTsdb.Fixtures do
  alias CaosTsdb.Repo
  alias CaosTsdb.Tag
  alias CaosTsdb.Sample
  alias CaosTsdb.Series
  alias CaosTsdb.Metric
  use Timex
  import CaosTsdb.DateTime.Helpers

  def fixture(_, assoc \\ [])

  def fixture(:token, assoc) do
    username = assoc[:username] || "some_user"
    claims = assoc[:claims] || %{}

    {:ok, jwt, _} = Guardian.encode_and_sign(username, :access, claims)
    jwt
  end

  def fixture(:tag, assoc) do
    Repo.insert! %Tag{
      key: assoc[:key] || "tag1",
      value: assoc[:value] || "value1",
      extra: %{"data key1" => "data value1"}
    }
  end

  def fixture(:tags, assoc) do
    [fixture(:tag),
     fixture(:tag,
       key: "tag2",
       value: "value 2",
       extra: %{"data key1" => "data value1",
                "data key2" => "data value2"})]
  end

  def fixture(:metric, assoc) do
    Repo.insert! %Metric{
      name: assoc[:name] || "metric1",
      type: assoc[:type] || "type1"
    }
  end

  def fixture(:series, assoc) do
    metric = assoc[:metric] || fixture(:metric)
    period = assoc[:period] || 3600
    tags = assoc[:tags] || [fixture(:tag)]

    series = %Series{
      metric_name: metric.name,
      period: period
    }
    |> Repo.insert!
    |> Repo.preload(:tags)
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:tags, tags)
    |> Repo.update!
  end

  def fixture(:samples, assoc) do
    series = assoc[:series] || fixture(:series)
    t0 = assoc[:from] || epoch()
    n = assoc[:repeat] || 1
    value_type = assoc[:values] || :rand

    _samples = Range.new(0, n-1) |> Enum.map(fn(x) ->
      value = case value_type do
                :rand -> :rand.uniform()
                :linear -> x+1.0
              end
      sample = %Sample{series_id: series.id,
                       timestamp: t0 |> Timex.shift(seconds: x*series.period),
                       value: value}
      Repo.insert! sample
    end)
  end
end
