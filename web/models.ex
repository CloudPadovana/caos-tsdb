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

defmodule CaosTsdb.Models.Helpers do
  import Ecto.Changeset

  @spec validate_immutable(Ecto.Changeset.t, atom) :: Ecto.Changeset.t
  def validate_immutable(changeset, field) do
    validate_change changeset, field, fn _, newvalue ->
      case Map.get(changeset.data, field) do
        ^newvalue -> []
        nil -> []
        _ -> [field: "must be kept immutable"]
      end
    end
  end

  @spec validate_immutable_unless_overwrite(Ecto.Changeset.t, atom, atom) :: Ecto.Changeset.t
  def validate_immutable_unless_overwrite(changeset, field, overwrite_field) do
    unless get_field(changeset, overwrite_field) do
      validate_immutable(changeset, field)
    else
      changeset
    end
  end
end
