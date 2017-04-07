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

defmodule CaosTsdb.Tag do
  use CaosTsdb.Web, :model

  @primary_key {:id, :id, autogenerate: true}
  @derive {Phoenix.Param, key: :id}
  schema "tags" do
    field :key, :string, primary_key: true
    field :value, :string, primary_key: true

    field :extra, :map

    many_to_many :series, CaosTsdb.Series, join_through: CaosTsdb.SeriesTag

    has_many :metadata, CaosTsdb.TagMetadata,
      foreign_key: :tag_id,
      references: :id

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:id, :key, :value, :extra])
    |> validate_required([:key, :value])
    |> validate_immutable(:id)
    |> validate_immutable(:key)
    |> validate_immutable(:value)
    |> unique_constraint(:key, name: "tags_key_value_index")
  end
end

