################################################################################
#
# caos-api - CAOS backend
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

defmodule CaosApi.ProjectTest do
  use CaosApi.ModelCase

  alias CaosApi.Project

  @project %Project{id: "an id", name: "a name"}
  @valid_attrs %{id: "an id", name: "a new name"}

  test "changeset with valid creation" do
    changeset = Project.changeset(%Project{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid creation" do
    changeset = Project.changeset(%Project{}, %{name: "a name"})
    refute changeset.valid?
  end

  test "changeset with valid change" do
    changeset = Project.changeset(@project, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid change" do
    changeset = Project.changeset(@project, %{id: "a new id", name: "a new name"})
    refute changeset.valid?
  end
end
