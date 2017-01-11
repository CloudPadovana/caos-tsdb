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

defmodule CaosTsdb.Mixfile do
  use Mix.Project

  def project do
    [app: :caos_tsdb,
     version: "0.0.1",
     elixir: "~> 1.4",
     elixirc_paths: elixirc_paths(Mix.env),
     compilers: [:phoenix, :gettext] ++ Mix.compilers,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     aliases: aliases(),
     deps: deps()]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [mod: {CaosTsdb, []},
     applications: [:phoenix,
                    :cowboy,
                    :logger,
                    :gettext,
                    :timex,
                    :timex_ecto,
                    :phoenix_ecto,
                    :mariaex,
                    :guardian,
                    :conform,
                    :conform_exrm]]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_),     do: ["lib", "web"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [{:phoenix, "~> 1.2.0"},
     {:phoenix_ecto, "~> 3.2"},
     {:mariaex, "~> 0.8"},
     {:timex, "~> 3.1"},
     {:tzdata, "~> 0.1.8", override: true},
     {:timex_ecto, "~> 3.1"},
     {:gettext, "~> 0.11"},
     {:cowboy, "~> 1.0"},
     {:guardian, "~> 0.14.0"},

     # the override of exrm and conform in your deps is to tell Mix
     # that it can use your deps to fulfill the requirements for exrm
     # and conform that are declared in conform_exrm. The requirements
     # in conform_exrm are declared as optional, but are required in
     # order to ensure conform and exrm are compiled before
     # conform_exrm is.
     {:exrm, "~> 1.0.8", override: true},
     {:conform, "~> 2.0", override: true},
     {:conform_exrm, "~> 1.0"}]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    ["ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
     "ecto.reset": ["ecto.drop", "ecto.setup"],
     "test": ["ecto.create --quiet", "ecto.migrate", "test"]]
  end
end
