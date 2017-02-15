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

defmodule CaosTsdb.Repo.Migrations.CreateTagMetadata do
  use Ecto.Migration

  def change do
    create table(:tag_metadatas, primary_key: false) do
      add :tag_id, references(:tags, column: :id, type: :serial), primary_key: true
      add :timestamp, :datetime, primary_key: true

      add :metadata, :text

      timestamps()
    end

    create unique_index(:tag_metadatas, [:tag_id, :timestamp])
  end
end
