import Config

config :exsemantica, test_mode: false

config :mnesia,
  dir: to_charlist(Path.join([Path.dirname(__DIR__), "priv", "MnesiaESDB", "prod.#{node()}"]))
