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

defmodule CaosTsdb.Graphql.Helpers do
  def graphql_error(:no_arguments_given) do
    {:error, "No arguments given" }
  end

  def graphql_error(:multiple_results) do
    {:error, "Expected at most one result, but got more"}
  end

  def graphql_error(:not_found, name) do
    {:error, "#{name} not found" }
  end

  def changeset_to_graphql(changeset) do
    case changeset do
      {:error, error} -> {:error, changeset_errors(error.errors)}
      {:ok, _} -> changeset
    end
  end

  defp changeset_errors(errors) do
    errors
    |> Enum.map(fn {field, detail} ->
      %{message: changeset_error(field, detail)}
    end)
  end

  defp changeset_error(field, detail) do
    "Changeset error on `#{field}`: #{error_detail(detail)}"
  end

  defp error_detail({message, values}) do
    Enum.reduce values, message, fn {k, v}, acc ->
      String.replace(acc, "%{#{k}}", to_string(v))
    end
  end

  defp error_detail(message) do
    message
  end
end
