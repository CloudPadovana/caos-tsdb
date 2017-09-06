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
  render_errors: [view: CaosTsdb.ErrorView, accepts: ~w(json)]

# Configures Elixir's Logger
config :logger,
  level: :info, # Do not print debug messages in production
  format: "$date $time [$level]$levelpad $metadata $message",
  metadata: [
    :request_id,
    :application,
    :module,
    :function,
    :file,
    :line,
  ],
  backends: [
    :console,
    {LoggerFileBackend, :error_log},
    {LoggerFileBackend, :log},
  ]

config :logger, :error_log,
  path: "/var/log/caos/tsdb.error.log",
  level: :error

config :logger, :log,
  path: "/var/log/caos/tsdb.log",
  level: :info

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
    "k" => :crypto.strong_rand_bytes(64) |> Base.encode64 |> binary_part(0, 64),
    "kty" => "oct"
  },
  serializer: CaosTsdb.GuardianSerializer

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
