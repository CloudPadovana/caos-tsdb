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

defmodule CaosTsdb.Fixtures do
  alias CaosTsdb.Repo
  alias CaosTsdb.Sample
  alias CaosTsdb.Series
  alias CaosTsdb.Project
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

  def fixture(:project, assoc) do
    Repo.insert! %Project{
      id: assoc[:id] || "id1",
      name: assoc[:name] || "project1"
    }
  end

  def fixture(:metric, assoc) do
    Repo.insert! %Metric{
      name: assoc[:name] || "metric1"
    }
  end

  def fixture(:series, assoc) do
    project = assoc[:project] || fixture(:project)
    metric = assoc[:metric] || fixture(:metric)
    period = assoc[:period] || 3600

    Repo.insert! %Series{
      project_id: project.id,
      metric_name: metric.name,
      period: period
    }
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
