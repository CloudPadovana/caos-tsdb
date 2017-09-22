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
     version: "0.1.3",
     elixir: "~> 1.5",
     elixirc_paths: elixirc_paths(Mix.env),
     test_paths: test_paths(Mix.env),
     test_coverage: [tool: ExCoveralls],
     preferred_cli_env: [
       "coveralls": :test,
       "coveralls.detail": :test,
       "coveralls.post": :test,
       "coveralls.html": :test,
       "test.migrations": :migration_test,
     ],
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
     extra_applications: [
       :logger,
       :logger_file_backend,
     ]]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(:migration_test), do: ["lib", "web", "migration_test/support"]
  defp elixirc_paths(_), do: ["lib", "web"]

  # Specifies which paths to test per environment.
  defp test_paths(:test), do: ["test"]
  defp test_paths(:migration_test), do: ["migration_test"]
  defp test_paths(_), do: []

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:abacus, "~> 0.3.2"},
      {:absinthe, "~> 1.4.0-rc.0"},
      {:absinthe_plug, "~> 1.4.0-rc.0"},
      {:conform, "~> 2.5.2"},
      {:cowboy, "~> 1.1.2"},
      {:credo, "~> 0.8.6", only: [:dev, :test], runtime: false},
      {:distillery, "~> 1.5.1", runtime: false},
      {:excoveralls, "~> 0.7.2", only: :test},
      {:gettext, "~> 0.13.1"},
      {:guardian, "~> 0.14.5"},
      {:logger_file_backend, "~> 0.0.10"},
      {:mariaex, "~> 0.8.3"},
      {:phoenix, "~> 1.3.0"},
      {:phoenix_ecto, "~> 3.2.3"},
      {:timex, "~> 3.1.24"},
      {:timex_ecto, "~> 3.1.1"},
      {:tzdata, "~> 0.5.12", override: true},
    ]
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
     "test.migrations": ["ecto.drop", "test"],
     "test": ["ecto.create --quiet", "ecto.migrate", "test"]]
  end
end
