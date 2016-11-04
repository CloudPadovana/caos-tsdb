######################################################################
#
# Filename: fixtures.ex
# Created: 2016-09-19T10:34:49+0200
# Time-stamp: <2016-11-03T17:01:04cet>
# Author: Fabrizio Chiarello <fabrizio.chiarello@pd.infn.it>
#
# Copyright © 2016 by Fabrizio Chiarello
#
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
######################################################################

defmodule CaosApi.Fixtures do
  alias CaosApi.Repo
  alias CaosApi.Sample
  alias CaosApi.Series
  alias CaosApi.Project
  alias CaosApi.Metric
  use Timex
  import CaosApi.DateTime.Helpers

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
    t0 = assoc[:from] || epoch
    n = assoc[:repeat] || 1
    value_type = assoc[:values] || :rand

    samples = Range.new(0, n-1) |> Enum.map(fn(x) ->
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
