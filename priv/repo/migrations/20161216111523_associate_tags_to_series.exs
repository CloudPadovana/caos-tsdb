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

defmodule CaosTsdb.Repo.Migrations.AssociateTagsToSeries do
  defmodule MigrationModels do
    defmacro __using__(which) when is_atom(which) do
      apply(__MODULE__, which, [])
    end

    def models do
      module = __MODULE__
      quote do
        alias unquote(module).Tag
        alias unquote(module).Series
        alias unquote(module).SeriesTag
      end
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

      many_to_many :series, Series, join_through: SeriesTag

      timestamps()
    end
  end

  defmodule MigrationModels.Series do
    use Ecto.Schema
    use MigrationModels, :models

    @primary_key {:id, :id, autogenerate: true}
    schema "series" do
      field :project_id, :string, primary_key: true
      field :metric_name, :string, primary_key: true
      field :period, :integer, primary_key: true

      field :ttl, :integer
      field :last_timestamp, Timex.Ecto.DateTime

      many_to_many :tags, Tag, join_through: SeriesTag

      timestamps()
    end
  end

  defmodule MigrationModels.SeriesTag do
    use Ecto.Schema
    use MigrationModels, :models

    @primary_key false
    schema "series_tags" do
      belongs_to :series, Series
      belongs_to :tag, Tag

      timestamps()
    end
  end

  use Ecto.Migration

  alias CaosTsdb.Repo
  alias MigrationModels.Tag
  alias MigrationModels.Series
  alias MigrationModels.SeriesTag

  def up do
    _series = Series
    |> Repo.all
    |> Repo.preload(:tags)
    |> Enum.each(fn(s) ->
      tag = Tag
      |> Repo.get_by(%{
            key: "project",
            value: s.project_id})

      tags = s.tags ++ [tag]

      changeset = s
      |> Ecto.Changeset.change
      |> Ecto.Changeset.put_assoc(:tags, tags)

      Repo.update!(changeset)
    end)
  end
end
