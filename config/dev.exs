import Config

# Configure your database
config :exsemantica, Exsemantica.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
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
config :exsemantica, Exsemantica.ApplicationInfo,
  commit_sha_result: System.cmd("git", ["rev-parse", "--short", "HEAD"])

# 5 minutes per user token
config :exsemantica, Exsemantica.Authentication, minutes_grace: 5

# English locale by default
config :gettext, default_locale: "en"
