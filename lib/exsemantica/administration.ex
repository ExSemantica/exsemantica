defmodule Exsemantica.Administration do
  @moduledoc """
  Administration convenience functions
  """

  @doc """
  Initializes all that's needed to be done on an initial run of ExSemantica.

  For example, the Ecto repository will be migrated. Please make sure the
  database is empty.
  """
  def initialize() do
    :ok = Exsemantica.Repo.config() |> Ecto.Adapters.Postgres.storage_up()
    Ecto.Migrator.run(Exsemantica.Repo, :up, all: true)
  end
end
