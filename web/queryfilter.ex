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

# From https://medium.com/@kaisersly/filtering-from-params-in-phoenix-27b85b6b1354

defmodule CaosApi.QueryFilter do
  def filter(query, model, params, filters) when is_atom(filters) do
    filter(query, model, params, [filters,])
  end

  def filter(query, model, params, filters) when is_list(filters) do
    import Ecto.Query, only: [where: 2]

    where_clauses = cast(model, params, filters)

    query
    |> where(^where_clauses)
  end

  def cast(model, params, filters) do
    Ecto.Changeset.cast(model, params, filters)
    |> Map.fetch!(:changes)
    |> Map.to_list
  end
end
