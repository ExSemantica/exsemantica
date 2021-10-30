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
  secret_key_base: "p1peLoj+pYjgOQNCp1wzw/0igaVtg7vo6maBWaG45GGqGUcTUR6OjW8Mp2T/x0Vk",
  render_errors: [view: ExsemanticaPhxWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: ExsemanticaPhx.PubSub,
  live_view: [signing_salt: "oaarpDx3"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.12.18",
  default: [
    args: ~w(js/app.js --bundle --target=es2016 --outdir=../priv/static/assets),
    cd: Path.expand("../apps/exsemantica_phx/assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../apps/exsemantica_phx/deps", __DIR__)}
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
