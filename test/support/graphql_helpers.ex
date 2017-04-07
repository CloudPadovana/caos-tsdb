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

defmodule CaosTsdb.Test.Support.GraphqHelpers do
  import CaosTsdb.DateTime.Helpers

  def tag_to_json(tag, fields \\ [:id, :key, :value]) do
    %{
      id: %{"id" => "#{tag.id}"},
      key: %{"key" => tag.key},
      value: %{"value" => tag.value}
    } |> Map.take(fields)
    |> Map.values
    |> Enum.reduce(%{}, fn (map, acc) -> Map.merge(acc, map) end)
  end
  def tags_to_json(tags, fields \\ [:id, :key, :value]) do
    tags
    |> Enum.map(&(tag_to_json(&1, fields)))
  end

  def json_to_tag(json) do
    %{
      id: json["id"],
      key: json["key"],
      value: json["value"]
    }
  end

  def tag_metadata_to_json(tag_metadata, fields \\ [:timestamp, :metadata]) do
    ts = case tag_metadata.timestamp do
      nil -> nil
      ts -> ts |> format_date!
    end

    %{
      metadata: %{"metadata" => tag_metadata.metadata},
      timestamp: %{"timestamp" => ts}
    } |> Map.take(fields)
    |> Map.values
    |> Enum.reduce(%{}, fn (map, acc) -> Map.merge(acc, map) end)
  end
  def tag_metadatas_to_json(tag_metadatas, fields \\ [:timestamp, :metadata]) do
    tag_metadatas
    |> Enum.map(&(tag_metadata_to_json(&1, fields)))
  end

  def metric_to_json(metric, fields \\ [:name, :type]) do
    %{
      name: %{"name" => metric.name},
      type: %{"type" => metric.type},
    } |> Map.take(fields)
    |> Map.values
    |> Enum.reduce(%{}, fn (map, acc) -> Map.merge(acc, map) end)
  end
  def metrics_to_json(metrics, fields \\ [:name, :type]) do
    metrics
    |> Enum.map(&(metric_to_json(&1, fields)))
  end

  def json_to_metric(json) do
    %{
      name: json["name"],
      type: json["type"]
    }
  end

  def series_to_json(series, fields \\ [:id, :period, :metric, :tags, :ttl, :last_timestamp]) do
    %{
      id: %{"id" => "#{series.id}"},
      period: %{"period" => series.period},
      metric: %{"metric" => %{"name" => series.metric_name}},
      tags: %{"tags" => series.tags |> tags_to_json()},
      ttl: %{"ttl" => series.ttl},
      last_timestamp: %{"last_timestamp" => series.last_timestamp}
    }
    |> Map.take(fields)
    |> Map.values
    |> Enum.reduce(%{}, fn (map, acc) -> Map.merge(acc, map) end)
  end
  def serieses_to_json(serieses, fields \\ [:id, :period, :metric, :tags, :ttl, :last_timestamp]) do
    serieses
    |> Enum.map(&(series_to_json(&1, fields)))
  end

  def sample_to_json(sample, fields \\ [:series, :timestamp, :value]) do
    %{
      series: %{"series" => %{"id" => "#{sample.series_id}"}},
      timestamp: %{"timestamp" => sample.timestamp |> format_date! },
      value: %{"value" => sample.value},
    }
    |> Map.take(fields)
    |> Map.values
    |> Enum.reduce(%{}, fn (map, acc) -> Map.merge(acc, map) end)
  end
  def samples_to_json(samples, fields \\ [:series, :timestamp, :value]) do
    samples
    |> Enum.map(&(sample_to_json(&1, fields)))
  end
end
