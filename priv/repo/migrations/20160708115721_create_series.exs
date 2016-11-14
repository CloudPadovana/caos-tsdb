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

defmodule CaosApi.Repo.Migrations.CreateSeries do
  use Ecto.Migration

  def change do
    create table(:series, primary_key: false) do
      add :id, :serial, primary_key: true

      add :project_id, references(:projects, column: :id, type: :string), primary_key: true
      add :metric_name, references(:metrics, column: :name, type: :string), primary_key: true
      add :period, :integer, primary_key: true
      add :ttl, :integer
      add :last_timestamp, :datetime
      timestamps()
    end

    create unique_index(:series, [:project_id, :metric_name, :period])
  end
end
