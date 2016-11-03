defmodule CaosApi.Mixfile do
  use Mix.Project

  def project do
    [app: :caos_api,
     version: "0.0.1",
     elixir: "~> 1.3",
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
    [mod: {CaosApi, []},
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
  defp elixirc_paths(_),     do: ["lib", "web"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [{:phoenix, "~> 1.2.0"},
     {:phoenix_pubsub, "~> 1.0"},
     {:phoenix_ecto, "~> 3.0"},
     {:mariaex, ">= 0.0.0"},
     {:timex, "~> 2.2"},
     {:timex_ecto, "~> 1.1"},
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
     "test": ["ecto.create --quiet", "ecto.migrate", "test"]]
  end
end
