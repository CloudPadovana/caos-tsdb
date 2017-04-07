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

# From https://medium.com/@kaisersly/filtering-from-params-in-phoenix-27b85b6b1354

defmodule CaosTsdb.QueryFilter do
  def filter(query, model, params, key) when is_atom(key) do
    filter(query, model, params, [key,])
  end

  def filter(query, model, params, keys) when is_list(keys) do
    import Ecto.Query, only: [where: 2]

    _where_clauses = build_where_clauses(model, params, keys)
    |> Enum.reduce(query, fn clause, query ->
      query |> where(^clause)
    end)
  end

  defp build_where_clauses(model, params, keys) do
    cast(model, params, keys)
    |> Map.fetch!(:changes)
    |> Map.to_list
    |> Enum.map(fn({k, v}) -> build_where_clause(k, v) end)
  end

  defp build_where_clause(name, clause) when is_binary(clause) do
    import Ecto.Query, only: [dynamic: 2]

    if String.match?(clause, ~r/\*/) do
      # FIXME: this could end up to be case-sensitive or insensitive,
      # depending on various factors. To force case sensitive use
      # `LIKE BINARY "..."`
      clause = String.replace(clause, "*", "%")
      dynamic([w], like(field(w, ^name), ^clause))
    else
      Keyword.new([{name, clause}])
    end
  end

  defp build_where_clause(name, clause) do
    Keyword.new([{name, clause}])
  end

  defp cast(model, params, keys) when is_list(keys) do
    keys
    |> Enum.reduce(model, fn(key, m) ->
      if is_atom(key) do
        Ecto.Changeset.cast(m, params, [key,])
      else
        cast_deep(m, params, key)
      end
    end)
  end

  defp cast_deep(model, params, keys) when is_map(keys) do
    key = keys |> Map.keys |> List.first

    deep_key = keys |> Map.get(key)
    value = get_in(params, deep_key)
    kv = %{key => value}

    Ecto.Changeset.cast(model, kv, [key,])
  end
end
