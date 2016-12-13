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

defmodule CaosTsdb.MigrationTest.ProjectToTagsMigrationTest do
  use CaosTsdb.MigrationTest.MigrationCase, target_migration: 20161213154617

  test "Migration on empty DB", _context do
    tags = Tag
    |> Repo.all

    assert tags == []
  end

  def before_migration(20161213154617) do
    Repo.insert! %Project{id: "id1", name: "name1"}
    Repo.insert! %Project{id: "id2", name: "name2"}
  end
  def before_migration(_) do
  end

  @before_migration &__MODULE__.before_migration/1
  test "Projects are copied to tags", _context do
    tags = Tag
    |> Repo.all
    |> Enum.map(fn(t) -> %{key: t.key, value: t.value, extra: t.extra} end)

    assert tags == [%{key: "project", value: "id1", extra: %{"name" => "name1"}},
                    %{key: "project", value: "id2", extra: %{"name" => "name2"}}]
  end
end
