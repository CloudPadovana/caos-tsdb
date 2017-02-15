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

defmodule CaosTsdb.MigrationTest.TagExtraToTagMetadataMigrationTest do
  use CaosTsdb.MigrationTest.MigrationCase, target_migration: 20170215090656

  test "Migration on empty DB", _context do
    tag_metadatas = TagMetadata
    |> Repo.all

    assert tag_metadatas == []
  end

  def before_migration(20170214111815) do
    Repo.insert! %Tag{key: "key1", value: "value1", extra: %{"extra key1" => "extra value1"}}
    Repo.insert! %Tag{key: "key2", value: "value1", extra: %{"extra key1" => "extra value3"}}
    Repo.insert! %Tag{key: "key3", value: "value1", extra: %{"extra key2" => "extra value11"}}
    Repo.insert! %Tag{key: "key4", value: "value1", extra: %{"extra key1" => 8}}
    Repo.insert! %Tag{key: "key1", value: "value2", extra: %{"extra key4" => "extra value17"}}
    Repo.insert! %Tag{key: "key1", value: "value3", extra: %{"extra key1" => 4}}

  end
  def before_migration(_) do
  end

  @before_migration &__MODULE__.before_migration/1
  test "Tag's extra are copied to tag metadata", _context do
    tags = Tag
    |> Repo.all
    |> Enum.each(fn(t) ->
      {:ok, metadata} = Poison.encode(t.extra)
      timestamp = t.updated_at

      tag_metadata = TagMetadata
      |> Repo.get_by(tag_id: t.id, timestamp: timestamp)

      assert tag_metadata.metadata == metadata
    end)
  end
end
