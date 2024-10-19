import Config

# Configure your database
config :exsemantica, Exsemantica.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "172.17.0.1",
  database: "exsemantica_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# Guardian secret
config :exsemantica, Exsemantica.Guardian,
  issuer: "exsemantica",
  secret_key: "K2PHGmL5JbjPZTcbKTSctLNbN0GjUE6g/AJpDwEp2W4TKW0vxt4sFKHEC05gzJHF"

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Commit SHA for Git, displayed throughout the site
# Also define a hostname
config :exsemantica, Exsemantica.ApplicationInfo,
  commit_sha_result: System.cmd("git", ["rev-parse", "--short", "HEAD"]),
  chat_hostname: "192.168.88.19"

# 5 minutes per user token
config :exsemantica, Exsemantica.Authentication, minutes_grace: 5
