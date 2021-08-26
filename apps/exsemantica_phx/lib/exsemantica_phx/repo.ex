defmodule ExsemanticaPhx.Repo do
  use Ecto.Repo,
    otp_app: :exsemantica_phx,
    adapter: Ecto.Adapters.Postgres
end
