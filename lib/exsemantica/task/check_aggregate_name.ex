defmodule Exsemantica.Task.CheckAggregateName do
  @moduledoc """
  A task that transforms the name of an aggregate
  """
  @behaviour Exsemantica.Task
  import Ecto.Query

  @impl true
  def run(%{guess: guess}) do
    data =
      Exsemantica.Repo.one(
        from a in Exsemantica.Repo.Aggregate,
          where: ilike(a.name, ^guess),
          select: a
      )

    case data do
      # Couldn't find the aggregate
      nil ->
        {:error, :not_found}

      aggregate ->
        {:ok, %{id: aggregate.id, name: aggregate.name, identical?: aggregate.name == guess}}
    end
  end
end
