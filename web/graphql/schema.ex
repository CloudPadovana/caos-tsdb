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

defmodule CaosTsdb.Graphql.Schema do
  use Absinthe.Schema
  import_types CaosTsdb.Graphql.Types

  alias CaosTsdb.Graphql.Resolver.TagResolver
  alias CaosTsdb.Graphql.Resolver.MetricResolver
  alias CaosTsdb.Graphql.Resolver.SeriesResolver

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
  end

  mutation do
    field :create_tag, :tag do
      arg :key, non_null(:string)
      arg :value, non_null(:string)
      resolve &TagResolver.get_or_create/2
    end

    field :create_metric, :metric do
      arg :name, non_null(:string)
      arg :type, :string
      resolve &MetricResolver.get_or_create/2
    end

    field :update_metric, :metric do
      arg :name, non_null(:string)
      arg :type, :string
      resolve &MetricResolver.update/2
    end

  end
end
