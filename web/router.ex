################################################################################
#
# caos-tsdb - CAOS Time-Series DB
#
# Copyright © 2016 INFN - Istituto Nazionale di Fisica Nucleare (Italy)
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

defmodule CaosTsdb.Router do
  use CaosTsdb.Web, :router
  alias CaosTsdb.APIVersion

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :api_auth do
    plug Guardian.Plug.VerifyHeader, realm: "Bearer"
    plug Guardian.Plug.LoadResource
  end

  pipeline :api_auth_ensure do
    plug Guardian.Plug.EnsureAuthenticated, handler: CaosTsdb.AuthErrorHandler
  end

  pipeline :v1 do
    plug APIVersion, version: :v1
  end

  scope "/api/v1", CaosTsdb do
    pipe_through [:v1, :api, :api_auth]

    resources "/token", TokenController, only: [:create], singleton: true
    resources "/status", StatusController, only: [:index]
  end

  scope "/api/v1", CaosTsdb do
    pipe_through [:v1, :api, :api_auth, :api_auth_ensure]

    resources "/tags", TagController, param: "id", except: [:new, :edit, :delete]
    resources "/metrics", MetricController, param: "name", except: [:new, :edit, :delete]

    resources "/series", SeriesController, param: "id", except: [:new, :edit, :delete] do
      get "/grid", SeriesController, :grid, as: "grid"
      get "/samples", SampleController, :show, as: "samples"
    end

    resources "/samples", SampleController, only: [:show, :create], singleton: true

    resources "/aggregate", AggregateController, only: [:show], singleton: true
  end
end
