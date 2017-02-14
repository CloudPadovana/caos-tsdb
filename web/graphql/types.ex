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

defmodule CaosTsdb.Graphql.Types do
  use Absinthe.Schema.Notation

  alias CaosTsdb.Graphql.Resolver.TagResolver
  alias CaosTsdb.Graphql.Resolver.MetricResolver
  alias CaosTsdb.Graphql.Resolver.SeriesResolver
  scalar :datetime, description: "ISOz datetime" do
    parse &Timex.parse(&1.value, "%FT%TZ", :strftime)
    serialize &Timex.format!(&1, "%FT%TZ", :strftime)
  end

  input_object :tag_primary do
    field :id, :id
    field :key, :string
    field :value, :string
  end

  object :tag do
    import_fields :tag_primary

    field :series, list_of(:series) do
      resolve fn tag, _, _ ->
        batch({TagResolver, :series_by_tag}, tag.id, fn batch_results ->
          {:ok, Map.get(batch_results, tag.id, [])}
        end)
      end
    end
  end

  input_object :metric_primary do
    field :name, :string
  end

  object :metric do
    import_fields :metric_primary

    field :type, :string

    field :series, list_of(:series) do
      resolve fn metric, _, _ ->
        batch({MetricResolver, :series_by_metric}, metric.name, fn batch_results ->
          {:ok, Map.get(batch_results, metric.name, [])}
        end)
      end
    end

  end

  input_object :series_primary do
    field :id, :id
    field :period, :integer

    field :metric, :metric do
      resolve fn series, _, _ ->
        batch({SeriesResolver, :metric_by_series}, series.metric_name, fn batch_results ->
          {:ok, Map.get(batch_results, series.metric_name, [])}
        end)
      end
    end

    field :tags, list_of(:tag) do
      resolve fn series, _, _ ->
        batch({SeriesResolver, :tags_by_series}, series.id, fn batch_results ->
          {:ok, Map.get(batch_results, series.id, [])}
        end)
      end
    end
  end

  object :series do
    import_fields :series_primary

    field :ttl, :integer
    field :last_timestamp, :datetime
  end
end
