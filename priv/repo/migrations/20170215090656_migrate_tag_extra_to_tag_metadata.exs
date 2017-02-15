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

defmodule CaosTsdb.Repo.Migrations.MigrateTagExtraToTagMetadata do
  defmodule MigrationModels do
    defmacro __using__(which) when is_atom(which) do
      apply(__MODULE__, which, [])
    end

    def models do
      module = __MODULE__
      quote do
        alias unquote(module).Tag
        alias unquote(module).TagMetadata
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

      timestamps()
    end
  end

  defmodule MigrationModels.TagMetadata do
    use Ecto.Schema
    use MigrationModels, :models

    @primary_key false
    schema "tag_metadatas" do
      field :tag_id, :id, primary_key: true
      field :timestamp, Timex.Ecto.DateTime, primary_key: true

      field :metadata, :string

      timestamps()
    end
  end

  use Ecto.Migration

  alias CaosTsdb.Repo
  alias MigrationModels.Tag
  alias MigrationModels.TagMetadata

  @spec tag_metadata_from_tag(Tag.t) :: TagMetadata.t
  defp tag_metadata_from_tag(t) do
    metadata = case Poison.encode(t.extra) do
                 {:ok, metadata} -> metadata
                 {:error, _} -> nil
               end

    %TagMetadata{
      tag_id: t.id,
      metadata: metadata,
      timestamp: t.updated_at
    }
  end

  def up do
    _tags = Tag
    |> Repo.all
    |> Enum.each(fn(t) ->
      tag_metadata = tag_metadata_from_tag(t)
      Repo.insert! tag_metadata, on_confict: :replace_all
    end)
  end
end
