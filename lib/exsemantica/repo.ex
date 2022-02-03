defmodule Exsemantica.Repo do
  use Ecto.Repo,
    otp_app: :exsemantica,
    adapter: Ecto.Adapters.SQLite3
end
