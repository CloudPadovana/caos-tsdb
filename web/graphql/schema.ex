################################################################################
#
# caos-tsdb - CAOS Time-Series DB
#
# Copyright © 2017, 2018 INFN - Istituto Nazionale di Fisica Nucleare (Italy)
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

defmodule CaosTsdb.Graphql.Schema do
  use Absinthe.Schema
  import_types CaosTsdb.Graphql.Types

  import CaosTsdb.DateTime.Helpers
  alias CaosTsdb.Graphql.Resolver.TagResolver
  alias CaosTsdb.Graphql.Resolver.MetricResolver
  alias CaosTsdb.Graphql.Resolver.SeriesResolver
  alias CaosTsdb.Graphql.Resolver.SampleResolver
  alias CaosTsdb.Graphql.Resolver.AggregateResolver
  alias CaosTsdb.Graphql.Resolver.ExpressionResolver

  query do
    field :tag, :tag do
      arg :id, :id
      arg :key, :string
      arg :value, :string
      resolve &TagResolver.get_one/2
    end

    field :tags, list_of(:tag) do
      arg :id, :id
      arg :key, :string
      arg :value, :string
      resolve &TagResolver.get_all/2
    end

    field :metric, :metric do
      arg :name, :string
      resolve &MetricResolver.get_one/2
    end

    field :metrics, list_of(:metric) do
      arg :name, :string
      arg :type, :string
      resolve &MetricResolver.get_all/2
    end

    field :series, :series do
      arg :id, :id
      arg :metric, :metric_primary
      arg :period, :integer
      arg :tags, list_of(:tag_primary)
      resolve &SeriesResolver.get_one/2
    end

    field :sample, :sample do
      arg :series, non_null(:series_primary)
      arg :timestamp, non_null(:datetime)
      resolve &SampleResolver.get_one/2
    end

    field :samples, list_of(:sample) do
      arg :series, non_null(:series_primary)
      arg :from, :datetime, default_value: epoch()
      arg :to, :datetime, default_value: Timex.now
      resolve &SampleResolver.get_all/2
    end

    field :aggregate, list_of(:sample) do
      arg :series, non_null(:series_group)
      arg :from, :datetime, default_value: epoch()
      arg :to, :datetime, default_value: Timex.now
      arg :granularity, :integer
      arg :function, :aggregate_function, default_value: :count
      arg :downsample, :aggregate_function, default_value: :none
      arg :fill, :fill_policy, default_value: :none

      resolve &AggregateResolver.aggregate/2
    end

    field :expression, list_of(:sample) do
      arg :from, :datetime, default_value: epoch()
      arg :to, :datetime, default_value: Timex.now
      arg :granularity, :integer

      arg :expression, non_null(:string)
      arg :terms, list_of(:expression_term)

      resolve &ExpressionResolver.expression/2
    end
  end

  mutation do
    field :create_tag, :tag do
      arg :key, non_null(:string)
      arg :value, non_null(:string)
      resolve &TagResolver.get_or_create/2
    end

    field :create_tag_metadata, :tag_metadata do
      arg :tag, non_null(:tag_primary)
      arg :timestamp, non_null(:datetime)
      arg :metadata, non_null(:string)
      resolve &TagResolver.create_tag_metadata/2
    end

    field :create_metric, :metric do
      arg :name, non_null(:string)
      arg :type, :string
      resolve &MetricResolver.get_or_create/2
    end

    field :create_series, :series do
      arg :metric, non_null(:metric_primary)
      arg :period, non_null(:integer)
      arg :tags, non_null(list_of(non_null(:tag_primary)))
      resolve &SeriesResolver.get_or_create/2
    end

    field :create_sample, :sample do
      arg :series, non_null(:series_primary)
      arg :timestamp, non_null(:datetime)
      arg :value, non_null(:float)
      arg :overwrite, :boolean, default_value: false
      resolve &SampleResolver.create/2
    end
  end
end
