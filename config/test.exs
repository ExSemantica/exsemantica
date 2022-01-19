import Config

config :mnesia,
  dir: to_charlist(Path.join([Path.dirname(__DIR__), "priv", "MnesiaTEST.#{node()}"]))
