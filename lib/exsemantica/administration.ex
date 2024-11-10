defmodule Exsemantica.Administration do
  @moduledoc """
  Administration convenience functions
  """
  require Logger

  @doc """
  Remotely initializes the database.
  """
  def initialize_database() do
    :ok = Exsemantica.Repo.config() |> Ecto.Adapters.Postgres.storage_up()
    Ecto.Migrator.run(Exsemantica.Repo, :up, all: true)

    Logger.info("Done initializing database")
  end
end
