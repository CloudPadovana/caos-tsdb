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

defmodule CaosTsdb.Repo.Migrations.MigrateProjectsToTags do
  defmodule MigrationModels do
    defmacro __using__(which) when is_atom(which) do
      apply(__MODULE__, which, [])
    end

    def models do
      module = __MODULE__
      quote do
        alias unquote(module).Project
        alias unquote(module).Tag
      end
    end
  end

  defmodule MigrationModels.Project do
    use Ecto.Schema
    use MigrationModels, :models

    @primary_key {:id, :string, []}
    schema "projects" do
      field :name, :string

      timestamps()
    end
  end

  defmodule MigrationModels.Tag do
    use Ecto.Schema
    use MigrationModels, :models

    @primary_key {:id, :id, autogenerate: true}
    schema "tags" do
      field :key, :string, primary_key: true
      field :value, :string, primary_key: true

      field :extra, :map

      timestamps()
    end
  end

  use Ecto.Migration

  alias CaosTsdb.Repo
  alias MigrationModels.Project
  alias MigrationModels.Tag

  def up do
    _projects = Project
    |> Repo.all
    |> Enum.each(fn(p) ->
      tag = %Tag{
        key: "project",
        value: p.id,
        extra: %{
          name: p.name
        }
      }
      Repo.insert! tag, on_confict: :replace_all
    end)
  end
end
