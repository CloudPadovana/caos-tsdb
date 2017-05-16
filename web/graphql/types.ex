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

  import CaosTsdb.DateTime.Helpers

  alias CaosTsdb.Graphql.Resolver.TagResolver
  alias CaosTsdb.Graphql.Resolver.MetricResolver
  alias CaosTsdb.Graphql.Resolver.SeriesResolver
  alias CaosTsdb.Graphql.Resolver.SampleResolver
  alias CaosTsdb.Graphql.Resolver.AggregateResolver

  alias CaosTsdb.Metric
  alias CaosTsdb.Series
  alias CaosTsdb.Sample
  alias CaosTsdb.TagMetadata

  scalar :datetime, description: "ISOz datetime" do
    parse &Timex.parse(&1.value, "%FT%TZ", :strftime)
    serialize &Timex.format!(&1, "%FT%TZ", :strftime)
  end

  scalar :unix_timestamp, description: "UNIX timestamp" do
    parse &Timex.from_unix(&1.value)
    serialize &Timex.to_unix(&1)
  end

  enum :aggregate_function, values: [:avg, :count, :min, :max, :sum, :std, :var]

  input_object :tag_primary do
    field :id, :id
    field :key, :string
    field :value, :string
  end

  object :tag do
    import_fields :tag_primary

    field :metadata, list_of(:tag_metadata) do
      arg :from, :datetime, default_value: nil
      arg :to, :datetime, default_value: nil

      resolve fn tag, args, _ ->
        batch({TagResolver, :batch_metadata_by_tag, args}, tag.id, fn batch_results ->
          {:ok, Map.get(batch_results, tag.id, [])}
        end)
      end
    end

    field :last_metadata, :tag_metadata do
      resolve fn tag, _, _ ->
        batch({TagResolver, :batch_last_metadata_by_tag}, tag.id, fn batch_results ->
          {:ok, Map.get(batch_results, tag.id, %TagMetadata{})}
        end)
      end
    end

    field :last_sample, :sample do
      arg :series, non_null(:series_primary)

      resolve fn
        tag, args = %{series: %{tags: tags}}, context ->
          SampleResolver.get_last(args |> put_in([:series, :tags], [%{id: tag.id},] ++ tags), context)

        tag, args, context ->
          SampleResolver.get_last(args |> put_in([:series, :tags], [%{id: tag.id},]), context)
      end
    end

    field :last_sample_value, :float do
      arg :series, non_null(:series_primary)

      resolve fn
        tag, args = %{series: %{tags: tags}}, context ->
          SampleResolver.get_last_value(args |> put_in([:series, :tags], [%{id: tag.id},] ++ tags), context)

        tag, args, context ->
          SampleResolver.get_last_value(args |> put_in([:series, :tags], [%{id: tag.id},]), context)
      end
    end

    field :series, list_of(:series) do
      arg :metric, :metric_primary
      arg :period, :integer
      arg :tags, list_of(:tag_primary)

      resolve fn
        tag, args = %{tags: tags}, context ->
          SeriesResolver.get_all(%{args | tags: [%{id: tag.id},] ++ tags}, context)

        tag, args, _ ->
          batch({SeriesResolver, :batch_by_tag, args}, tag.id, fn batch_results ->
            {:ok, Map.get(batch_results, tag.id, [])}
          end)
      end
    end
  end

  object :tag_metadata do
    field :timestamp, :datetime
    field :metadata, :string

    field :field, :string do
      arg :key, list_of(:string)
      resolve &(TagResolver.metadata_field(:string, &1, &2, &3))
    end

    field :boolean_field, :boolean do
      arg :key, list_of(:string)
      resolve &(TagResolver.metadata_field(:boolean, &1, &2, &3))
    end

    field :float_field, :float do
      arg :key, list_of(:string)
      resolve &(TagResolver.metadata_field(:float, &1, &2, &3))
    end

    field :integer_field, :integer do
      arg :key, list_of(:string)
      resolve &(TagResolver.metadata_field(:integer, &1, &2, &3))
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
        batch({SeriesResolver, :batch_by_metric}, metric.name, fn batch_results ->
          {:ok, Map.get(batch_results, metric.name, [])}
        end)
      end
    end
  end

  input_object :series_primary do
    field :id, :id
    field :period, :integer
    field :metric, :metric_primary
    field :tags, list_of(:tag_primary)
  end

  input_object :series_group do
    import_fields :series_primary

    field :tag, :tag_primary
  end

  object :series do
    field :id, :id
    field :period, :integer

    field :ttl, :integer
    field :last_timestamp, :datetime

    field :metric, :metric do
      resolve fn series, _, _ ->
        batch({MetricResolver, :batch_by_series}, series.metric_name, fn batch_results ->
          {:ok, Map.get(batch_results, series.metric_name, %Metric{})}
        end)
      end
    end

    field :tags, list_of(:tag) do
      resolve fn series, _, _ ->
        batch({TagResolver, :batch_by_series}, series.id, fn batch_results ->
          {:ok, Map.get(batch_results, series.id, [])}
        end)
      end
    end

    field :samples, list_of(:sample) do
      arg :from, :datetime, default_value: epoch()
      arg :to, :datetime, default_value: Timex.now

      resolve fn series, args, _ ->
        batch({SampleResolver, :batch_by_series, args}, series.id, fn batch_results ->
          {:ok, Map.get(batch_results, series.id, [])}
        end)
      end
    end

    field :sample, :sample do
      arg :timestamp, :datetime

      resolve fn series, args, _ ->
        batch({SampleResolver, :batch_by_series, args}, series.id, fn batch_results ->
          {:ok, Map.get(batch_results, series.id, %Sample{})}
        end)
      end
    end

    field :last_sample, :sample do
      resolve fn series, _, _ ->
        batch({SampleResolver, :batch_last_by_series}, series.id, fn batch_results ->
          {:ok, Map.get(batch_results, series.id, %Sample{})}
        end)
      end
    end

    field :aggregate, list_of(:sample) do
      arg :from, :datetime, default_value: epoch()
      arg :to, :datetime, default_value: Timex.now
      arg :granularity, :integer
      arg :function, :aggregate_function, default_value: :count

      resolve fn series, args, context ->
        AggregateResolver.aggregate(args |> put_in([:series], Map.take(series, [:id])) , context)
      end
    end
  end

  object :sample do
    field :timestamp, :datetime
    field :unix_timestamp, :unix_timestamp do
      resolve fn sample, _, _ -> {:ok, sample.timestamp} end
    end
    field :value, :float

    field :series, :series do
      resolve fn sample, _, _ ->
        batch({SeriesResolver, :batch_by_sample}, sample.series_id, fn batch_results ->
          {:ok, Map.get(batch_results, sample.series_id, %Series{})}
        end)
      end
    end
  end
end
