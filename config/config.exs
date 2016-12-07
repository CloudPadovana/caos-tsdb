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

# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :caos_tsdb,
  ecto_repos: [CaosTsdb.Repo]

# Configures the endpoint
config :caos_tsdb, CaosTsdb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "SysJSKR79rwPkpOd7IE1CnaPwn/QMaCINo3wYsSBspU+ctT/fc8JXUE2Ki4FYAa/",
  render_errors: [view: CaosTsdb.ErrorView, accepts: ~w(json)],
  pubsub: [name: CaosTsdb.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# AUTH
config :caos_tsdb, Auth,
  identity: [username: "admin", password: "ADMIN_PASS"]

# Configures Guardian (for JWT auth)
config :guardian, Guardian,
  allowed_algos: ["HS512"],
  verify_module: Guardian.JWT,
  issuer: "CaosTsdb",
  ttl: { 3600, :seconds },
  verify_issuer: true,
  secret_key: %{
    "k" => "vUczE4q9U0SF2eQIUTMJvw==",
    "kty" => "oct"
  },
  serializer: CaosTsdb.GuardianSerializer

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
