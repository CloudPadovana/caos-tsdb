# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :caos_api,
  ecto_repos: [CaosApi.Repo]

# Configures the endpoint
config :caos_api, CaosApi.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "SysJSKR79rwPkpOd7IE1CnaPwn/QMaCINo3wYsSBspU+ctT/fc8JXUE2Ki4FYAa/",
  render_errors: [view: CaosApi.ErrorView, accepts: ~w(json)],
  pubsub: [name: CaosApi.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# AUTH
config :caos_api, Auth,
  identity: [username: "admin", password: "ADMIN_PASS"]

# Configures Guardian (for JWT auth)
config :guardian, Guardian,
  allowed_algos: ["HS512"],
  verify_module: Guardian.JWT,
  issuer: "CaosApi",
  ttl: { 3600, :seconds },
  verify_issuer: true,
  secret_key: %{
    "k" => "vUczE4q9U0SF2eQIUTMJvw==",
    "kty" => "oct"
  },
  serializer: CaosApi.GuardianSerializer

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
