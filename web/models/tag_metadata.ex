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

defmodule CaosTsdb.TagMetadata do
  use CaosTsdb.Web, :model

  @primary_key false
  schema "tag_metadatas" do
    field :tag_id, :id, primary_key: true
    field :timestamp, Timex.Ecto.DateTime, primary_key: true

    field :metadata, :string

    timestamps()

    belongs_to :tag, CaosTsdb.Tag,
      foreign_key: :tag_id,
      references: :id,
      define_field: false
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:tag_id, :timestamp, :metadata])
    |> validate_required([:tag_id, :timestamp])
    |> validate_immutable(:tag_id)
    |> validate_immutable(:timestamp)
    |> foreign_key_constraint(:tag_id)
    |> assoc_constraint(:tag)
    # the following line has this form due to mysql error format
    |> unique_constraint(:primary, name: "PRIMARY")
  end
end
