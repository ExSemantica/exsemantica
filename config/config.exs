import Config

config :exsemantica,
  ecto_repos: [Exsemantica.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Mnesia should save in `priv`
config :mnesia, dir: to_charlist(Path.expand("../priv/mnesia", __DIR__))

import_config "#{config_env()}.exs"
