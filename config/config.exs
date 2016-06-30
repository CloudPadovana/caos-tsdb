# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :api_storage,
  ecto_repos: [ApiStorage.Repo]

# Configures the endpoint
config :api_storage, ApiStorage.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "SysJSKR79rwPkpOd7IE1CnaPwn/QMaCINo3wYsSBspU+ctT/fc8JXUE2Ki4FYAa/",
  render_errors: [view: ApiStorage.ErrorView, accepts: ~w(json)],
  pubsub: [name: ApiStorage.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
