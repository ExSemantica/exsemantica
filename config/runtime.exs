import Config

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  guardian_secret =
    System.get_env("GUARDIAN_SECRET") ||
      raise """
      environment variable GUARDIAN_SECRET is missing.
      You can generate once by calling: mix guardian.gen.secret
      """

  config :exsemantica, Exsemantica.Auth.Guardian,
    issuer: "exsemantica",
    secret_key: guardian_secret

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :exsemantica, Exsemantica.Repo,
    # ssl: true,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6
end
