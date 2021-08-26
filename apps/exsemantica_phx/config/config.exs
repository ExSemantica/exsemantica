# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :exsemantica_phx,
  ecto_repos: [ExsemanticaPhx.Repo]

# Configures the endpoint
config :exsemantica_phx, ExsemanticaPhxWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "gTa5wZD8eeE52Bk96neSoChF3Pv5PkDS06vQsKWVEIHeGnkX5mwfT5nD2qIwYPK7",
  render_errors: [view: ExsemanticaPhxWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: ExsemanticaPhx.PubSub,
  live_view: [signing_salt: "zGm5KaLp"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
