######################################################################
#
# Filename: queryfilter.ex
# Created: 2016-07-12T11:36:36+0200
# Time-stamp: <2016-07-19T10:50:24cest>
# Author: Fabrizio Chiarello <fabrizio.chiarello@pd.infn.it>
#
# Copyright © 2016 by Fabrizio Chiarello
#
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
######################################################################

# From https://medium.com/@kaisersly/filtering-from-params-in-phoenix-27b85b6b1354

defmodule ApiStorage.QueryFilter do
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
