defmodule Exsemantica.Repo do
  use Ecto.Repo,
    otp_app: :exsemantica,
    adapter: Ecto.Adapters.Postgres
end
