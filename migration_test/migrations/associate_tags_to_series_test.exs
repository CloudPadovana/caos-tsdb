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

defmodule CaosTsdb.MigrationTest.AssociateTagsToSeriesTest do
  use CaosTsdb.MigrationTest.MigrationCase, target_migration: 20161216111523

  import CaosTsdb.DateTime.Helpers

  test "Migration on empty DB", _context do
    tags = Tag |> Repo.all
    assert tags == []

    series = Series |> Repo.all
    assert series == []

    series_tags = SeriesTag |> Repo.all
    assert series_tags == []
  end

  @a_timestamp Timex.now |> format_date! |> parse_date!

  def before_migration(20161213154617) do
    Repo.insert_all "projects", [%{id: "id1", name: "name1", inserted_at: @a_timestamp, updated_at: @a_timestamp},
                                 %{id: "id2", name: "name2", inserted_at: @a_timestamp, updated_at: @a_timestamp}]

    Repo.insert_all "metrics", [%{name: "metric1", inserted_at: @a_timestamp, updated_at: @a_timestamp},
                                %{name: "metric2", inserted_at: @a_timestamp, updated_at: @a_timestamp}]

    s1 = Repo.insert! %Series{project_id: "id1", metric_name: "metric1", period: 3600}
    s2 = Repo.insert! %Series{project_id: "id1", metric_name: "metric2", period: 3600}
    s3 = Repo.insert! %Series{project_id: "id2", metric_name: "metric1", period: 3600}
    s4 = Repo.insert! %Series{project_id: "id2", metric_name: "metric2", period: 86400}

    t1 = Repo.insert! %Tag{key: "some key", value: "some value"}
    t2 = Repo.insert! %Tag{key: "some key2", value: "some value2"}

    s1 = s1 |> Repo.preload(:tags)
    s3 = s3 |> Repo.preload(:tags)
    s4 = s4 |> Repo.preload(:tags)

    s1
    |> Ecto.Changeset.change
    |> Ecto.Changeset.put_assoc(:tags, s1.tags ++ [t1])
    |> Repo.update!

    s3
    |> Ecto.Changeset.change
    |> Ecto.Changeset.put_assoc(:tags, s3.tags ++ [t1])
    |> Repo.update!

    s4
    |> Ecto.Changeset.change
    |> Ecto.Changeset.put_assoc(:tags, s4.tags ++ [t2])
    |> Repo.update!
  end
  def before_migration(_) do
  end

  @before_migration &__MODULE__.before_migration/1
  test "Series are associated to tags", _context do
    tags = Tag
    |> where([t], t.key == "project")
    |> Repo.all
    |> Repo.preload(:series)

    data = tags |> Enum.map(fn(t)
      -> %{
        key: t.key, value: t.value,
        series: t.series |> Enum.map(fn(s)
          -> %{
            metric_name: s.metric_name,
            project_id: s.project_id,
            period: s.period
         } end) |> Enum.sort_by(fn s -> s.metric_name end)
     } end)

    assert data == [%{key: "project", value: "id1",
                      series: [
                        %{metric_name: "metric1",
                          project_id: "id1",
                          period: 3600},
                        %{metric_name: "metric2",
                          project_id: "id1",
                          period: 3600}]},

                    %{key: "project", value: "id2",
                      series: [
                        %{metric_name: "metric1",
                          project_id: "id2",
                          period: 3600},
                        %{metric_name: "metric2",
                          project_id: "id2",
                          period: 86400}]}]
  end

  @before_migration &__MODULE__.before_migration/1
  test "Existing tags are preserved", _context do
    tags = Tag
    |> where([t], t.key != "project")
    |> Repo.all
    |> Repo.preload(:series)

    data = tags |> Enum.map(fn(t)
      -> %{
        key: t.key, value: t.value,
        series: t.series |> Enum.map(fn(s)
          -> %{
            metric_name: s.metric_name,
            project_id: s.project_id,
            period: s.period
         } end) |> Enum.sort_by(fn s -> s.project_id end)
     } end)

    assert data == [%{key: "some key", value: "some value",
                      series: [
                        %{metric_name: "metric1",
                          project_id: "id1",
                          period: 3600},
                        %{metric_name: "metric1",
                          project_id: "id2",
                          period: 3600}]},

                    %{key: "some key2", value: "some value2",
                      series: [
                        %{metric_name: "metric2",
                          project_id: "id2",
                          period: 86400}]}]
  end
end
