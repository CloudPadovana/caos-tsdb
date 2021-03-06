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

default_logger_format = "\n$date $time [$level]$levelpad $metadata $message\n"
default_logger_metadata = [ :request_id, :application ]
default_logger_utc = true

# Configures Elixir's Logger
config :logger,
  level: :info,
  backends: [
    :console,
    {LoggerFileBackend, :error_file},
    {LoggerFileBackend, :log_file},
  ]

config :logger, :console,
  level: :info,
  utc_log: default_logger_utc,
  format: default_logger_format,
  metadata: default_logger_metadata

config :logger, :error_file,
  path: "/var/log/caos/tsdb.error.log",
  level: :error,
  utc_log: default_logger_utc,
  format: default_logger_format,
  metadata: default_logger_metadata


config :logger, :log_file,
  path: "/var/log/caos/tsdb.log",
  level: :info,
  utc_log: default_logger_utc,
  format: default_logger_format,
  metadata: default_logger_metadata

# AUTH
config :caos_tsdb, Auth,
  identity: [username: "admin", password: "ADMIN_PASS"]

# Threshold for foresee updates
config :caos_tsdb, ForeseenSample,
  threshold: 20

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
