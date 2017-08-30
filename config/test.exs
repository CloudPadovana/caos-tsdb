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

use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :caos_tsdb, CaosTsdb.Endpoint,
  http: [port: 4001],
  server: false

config :logger, level: :debug, backends: [:console]

# Configure your database
config :caos_tsdb, CaosTsdb.Repo,
  adapter: Ecto.Adapters.MySQL,
  username: "root",
  password: "",
  database: "caos_tsdb_test",
  hostname: System.get_env("CAOS_TSDB_DB_HOSTNAME") || "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
