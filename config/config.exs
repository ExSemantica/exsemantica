import Config

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: []

import_config "#{Mix.env()}.exs"
