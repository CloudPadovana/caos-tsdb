use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :caos_api, CaosApi.Endpoint,
  http: [port: 4001],
  server: false

config :logger, :console, level: :warn, format: "[$level] $message\n"

# Configure your database
config :caos_api, CaosApi.Repo,
  adapter: Ecto.Adapters.MySQL,
  username: "root",
  password: "",
  database: "caos_api_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
