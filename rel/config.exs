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

use Mix.Releases.Config,
  # This sets the default release built by `mix release`
  default_release: :caos_tsdb,
  # This sets the default environment used by `mix release`
  default_environment: Mix.env

# For a full list of config options for both releases
# and environments, visit https://hexdocs.pm/distillery/configuration.html

environment :prod do
  set include_erts: true
  set include_src: false

  set vm_args: "rel/vm.args"

  # This setting is necessary to suppress errors on release
  # generation.  Distillery checks for the presence of the cookie
  # parameter, even if we provide our custom value in "vm.args".
  set cookie: :prod
end

release :caos_tsdb do
  set version: System.get_env("CAOS_TSDB_RELEASE_VERSION") || current_version(:caos_tsdb)

  plugin Conform.ReleasePlugin
end
