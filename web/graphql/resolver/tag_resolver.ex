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

defmodule CaosTsdb.Graphql.Resolver.TagResolver do
  use CaosTsdb.Web, :resolver

  def get_one(args, _) when args == %{} do
    graphql_error(:no_arguments_given)
  end

  def get_one(args, _) do
    try do
      case Repo.get_by(Tag, args) do
        nil -> graphql_error(:not_found, "Tag")
        tag -> {:ok, tag}
      end
    rescue
      Ecto.MultipleResultsError -> graphql_error(:multiple_results)
    end
  end

  def find_all(args) do
    tags = Tag
    |> CaosTsdb.QueryFilter.filter(%Tag{}, args, [:id, :key, :value])
    |> Repo.all
  end

  def get_all(args, _) do
    tags = find_all(args)

    {:ok, tags}
  end

  def batch_by_series(_, series_ids) do
    ids = series_ids |> Enum.uniq

    Series
    |> where([s], s.id in ^ids)
    |> join(:inner, [s], t in assoc(s, :tags))
    |> preload([s, t], [tags: t])
    |> Repo.all
    |> Map.new(&{&1.id, &1.tags})
  end

  def batch_metadata_by_tag(_args = %{from: from, to: to}, tag_ids) do
    dynamic = dynamic([m], m.tag_id in ^tag_ids)
    dynamic = if from do
      dynamic([m], m.timestamp >= ^from and ^dynamic)
    else
      dynamic
    end
    dynamic = if to do
      dynamic([m], m.timestamp <= ^to and ^dynamic)
    else
      dynamic
    end

    TagMetadata
    |> where(^dynamic)
    |> order_by([m], [asc: m.timestamp])
    |> Repo.all
    |> Enum.group_by(&(&1.tag_id))
  end

  def metadata_field(_type, %{metadata: metadata}, %{key: key}, _context) do
    case Poison.decode(metadata) do
      {:ok, meta} -> {:ok, get_in(meta, key)}

      {:error, error} -> {:error, error}
    end
  end

  def batch_last_metadata_by_tag(_, tag_ids) do
    last_timestamps_by_ids =
      TagMetadata
      |> where([m], m.tag_id in ^tag_ids)
      |> group_by([m], [m.tag_id])
      |> select([m], %{tag_id: m.tag_id, last_timestamp: max(m.timestamp)})

    TagMetadata
    |> where([m], m.tag_id in ^tag_ids)
    |> join(:inner, [m], l in subquery(last_timestamps_by_ids), m.tag_id == l.tag_id and m.timestamp == l.last_timestamp)
    |> select([m], m)
    |> Repo.all
    |> Map.new(&{&1.tag_id, &1})
  end

  def create(args, _) when args == %{} do
    graphql_error(:no_arguments_given)
  end

  def create(args, _) do
    %Tag{}
    |> Tag.changeset(args)
    |> Repo.insert
    |> changeset_to_graphql
  end

  def get_or_create(args, context) do
    case Repo.get_by(Tag, args) do
      nil -> create(args, context)
      tag -> {:ok, tag}
    end
  end

  def create_tag_metadata(_args = %{tag: tag, timestamp: timestamp, metadata: metadata}, context) do
    {:ok, tag} = get_or_create(tag, context)

    %TagMetadata{}
    |> TagMetadata.changeset(%{tag_id: tag.id, timestamp: timestamp, metadata: metadata})
    |> Repo.insert
    |> changeset_to_graphql
  end
end
