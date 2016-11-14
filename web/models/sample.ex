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

defmodule CaosApi.Sample do
  use CaosApi.Web, :model

  @primary_key false
  schema "samples" do
    field :series_id, :id, primary_key: true
    field :timestamp, Timex.Ecto.DateTime, primary_key: true
    field :value, :float

    timestamps()

    belongs_to :series, CaosApi.Series,
      foreign_key: :series_id,
      references: :id,
      define_field: false

    field :force, :boolean, virtual: true
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:series_id, :timestamp, :value, :force])
    |> validate_required([:series_id, :timestamp])
    |> validate_immutable(:series_id)
    |> validate_immutable_unless_forced(:timestamp, :force)
    |> validate_immutable_unless_forced(:value, :force)
    |> foreign_key_constraint(:series_id)
    |> assoc_constraint(:series)
    # the following line has this form due to mysql error format
    |> unique_constraint(:primary, name: "PRIMARY")
  end
end
