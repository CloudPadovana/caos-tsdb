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

defmodule CaosTsdb.Web do
  @moduledoc """
  A module that keeps using definitions for controllers,
  views and so on.

  This can be used in your application as:

      use CaosTsdb.Web, :controller
      use CaosTsdb.Web, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below.
  """

  def model do
    quote do
      use Ecto.Schema
      use Timex.Ecto.Timestamps

      import Ecto
      import Ecto.Changeset
      import Ecto.Query

      import CaosTsdb.ValidateImmutable
    end
  end

  def controller do
    quote do
      use Phoenix.Controller

      alias CaosTsdb.Repo
      import Ecto
      import Ecto.Query

      import CaosTsdb.Router.Helpers
      import CaosTsdb.Gettext
      import CaosTsdb.DateTime.Helpers
      import CaosTsdb.QueryFilter
      import CaosTsdb.Helpers
    end
  end

  def view do
    quote do
      use Phoenix.View, root: "web/templates"

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_csrf_token: 0, get_flash: 2, view_module: 1]

      import CaosTsdb.Router.Helpers
      import CaosTsdb.ErrorHelpers
      import CaosTsdb.Gettext
      import CaosTsdb.DateTime.Helpers
    end
  end

  def router do
    quote do
      use Phoenix.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel

      alias CaosTsdb.Repo
      import Ecto
      import Ecto.Query
      import CaosTsdb.Gettext
    end
  end

  def resolver do
    quote do
      alias CaosTsdb.Repo
      import Ecto
      import Ecto.Query

      import CaosTsdb.Router.Helpers
      import CaosTsdb.Gettext
      import CaosTsdb.DateTime.Helpers
      alias CaosTsdb.QueryFilter
      import CaosTsdb.Helpers
      import CaosTsdb.Graphql.Helpers

      alias CaosTsdb.Graphql.Resolver.TagResolver
      alias CaosTsdb.Graphql.Resolver.MetricResolver
      alias CaosTsdb.Graphql.Resolver.SeriesResolver
      alias CaosTsdb.Graphql.Resolver.SampleResolver
      alias CaosTsdb.Graphql.Resolver.AggregateResolver
      alias CaosTsdb.Graphql.Resolver.ExpressionResolver

      alias CaosTsdb.Tag
      alias CaosTsdb.TagMetadata
      alias CaosTsdb.Metric
      alias CaosTsdb.Series
      alias CaosTsdb.SeriesTag
      alias CaosTsdb.Sample
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
