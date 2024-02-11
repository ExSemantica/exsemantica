defmodule Exsemantica.Admin.Aggregate do
  @moduledoc """
  Administrative conveniences to modify aggregates
  """
  def create(name, description) do
    {:ok, constrained} = name |> Exsemantica.Constrain.into_valid_aggregate()

    Exsemantica.Repo.insert(%Exsemantica.Repo.Aggregate{
      name: constrained,
      description: description
    })
  end

  def delete(id) do
    Exsemantica.Repo.get(Exsemantica.Repo.Aggregate, id)
    |> Exsemantica.Repo.delete()
  end

  def set_hidden(id, hidden) do
    Exsemantica.Repo.get(Exsemantica.Repo.Aggregate, id)
    |> Ecto.Changeset.change(%{hidden: hidden})
    |> Exsemantica.Repo.update()
  end

  def set_description(id, description) do
    Exsemantica.Repo.get(Exsemantica.Repo.Aggregate, id)
    |> Ecto.Changeset.change(%{description: description})
    |> Exsemantica.Repo.update()
  end
end
