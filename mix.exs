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

defmodule CaosTsdb.Mixfile do
  use Mix.Project

  def project do
    [app: :caos_tsdb,
     version: "0.0.1",
     elixir: "~> 1.3",
     elixirc_paths: elixirc_paths(Mix.env),
     test_paths: test_paths(Mix.env),
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
                    :phoenix_pubsub,
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
  defp elixirc_paths(:migration_test), do: ["lib", "web", "migration_test/support"]
  defp elixirc_paths(_),     do: ["lib", "web"]

  # Specifies which paths to test per environment.
  defp test_paths(:test), do: ["test"]
  defp test_paths(:migration_test), do: ["migration_test"]
  defp test_paths(_),     do: []

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [{:phoenix, "~> 1.2.0"},
     {:phoenix_pubsub, "~> 1.0"},
     {:phoenix_ecto, "~> 3.0"},
     {:mariaex, "~> 0.7"},
     {:timex, "~> 3.0"},
     {:timex_ecto, "~> 3.0"},
     {:gettext, "~> 0.11"},
     {:cowboy, "~> 1.0"},
     {:guardian, "~> 0.13.0"},

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
     "test.migrations": &test_migrations/1,
     "test": ["ecto.create --quiet",
              &ecto_migrate_maybe/1,
              "test"]]
  end

  defp ecto_migrate_maybe(args) do
    unless Mix.env == :migration_test do
      env_run(Mix.env, "ecto.migrate", args)
    end
  end

  defp test_migrations(args) do
    env_run(:migration_test, "test", args)
  end

  defp env_run(env, cmd, args) do
    args = ["--color" | args]

    IO.puts "==> Running MIX_ENV=#{env} mix #{cmd}"
    {_, res} = System.cmd "mix", [cmd | args],
      into: IO.binstream(:stdio, :line), env: [{"MIX_ENV", to_string(env)}]

    if res > 0 do
      System.at_exit(fn _ -> exit({:shutdown, 1}) end)
    end
  end
end
