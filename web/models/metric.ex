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

defmodule CaosTsdb.Metric do
  use CaosTsdb.Web, :model

  @metric_name_regex ~r|^[[:alpha:]][[:alnum:]_./]*$|

  @primary_key {:name, :string, []}
  @derive {Phoenix.Param, key: :name}
  schema "metrics" do
    field :type, :string

    timestamps()

    has_many :series, CaosTsdb.Series,
      foreign_key: :metric_name,
      references: :name
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :type])
    |> validate_required(:name)
    |> validate_format(:name, @metric_name_regex)
    |> validate_immutable(:name)
    |> unique_constraint(:name)
  end
end
