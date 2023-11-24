defmodule Exsemantica.Repo do
  @moduledoc """
  The Ecto PostgreSQL repositiory and its schemas reside in this namespace
  """
  use Ecto.Repo,
    otp_app: :exsemantica,
    adapter: Ecto.Adapters.Postgres
end
