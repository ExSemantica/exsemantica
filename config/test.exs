import Config

config :exsemantica, test_mode: true

config :mnesia,
  dir: to_charlist(Path.join([Path.dirname(__DIR__), "priv", "MnesiaESDB", "test.#{node()}"]))
