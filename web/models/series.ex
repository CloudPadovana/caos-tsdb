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

defmodule CaosTsdb.Series do
  use CaosTsdb.Web, :model

  @primary_key {:id, :id, autogenerate: true}
  @derive {Phoenix.Param, key: :id}
  schema "series" do
    field :project_id, :string, primary_key: true
    field :metric_name, :string, primary_key: true
    field :period, :integer, primary_key: true

    field :ttl, :integer
    field :last_timestamp, Timex.Ecto.DateTime

    timestamps()

    belongs_to :project, CaosTsdb.Project,
      foreign_key: :project_id,
      references: :id,
      define_field: false

    belongs_to :metric, CaosTsdb.Metric,
      foreign_key: :metric_name,
      references: :name,
      define_field: false
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:id, :project_id, :metric_name, :period, :ttl, :last_timestamp])
    |> validate_required([:project_id, :metric_name, :period])
    |> validate_immutable(:id)
    |> validate_immutable(:project_id)
    |> validate_immutable(:meter_name)
    |> foreign_key_constraint(:project_id)
    |> foreign_key_constraint(:metric_name)
    |> assoc_constraint(:project)
    |> assoc_constraint(:metric)
    |> unique_constraint(:project_id, name: "series_project_id_metric_name_period_index")
  end
end
