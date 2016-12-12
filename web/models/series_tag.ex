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

defmodule CaosTsdb.SeriesTag do
  use CaosTsdb.Web, :model

  @primary_key false
  schema "series_tags" do
    belongs_to :series, Series
    belongs_to :tag, Tag

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:series_id, :tag_id])
    |> validate_required([:series_id, :tag_id])
    |> validate_immutable(:series_id)
    |> validate_immutable(:tag_id)
    |> foreign_key_constraint(:series_id)
    |> foreign_key_constraint(:tag_id)
    |> assoc_constraint(:series)
    |> assoc_constraint(:tag)
    |> unique_constraint(:primary, name: "series_tags_series_id_tag_id_index")
  end
end
