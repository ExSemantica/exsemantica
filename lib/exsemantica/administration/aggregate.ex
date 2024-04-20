defmodule Exsemantica.Administration.Aggregate do
  @moduledoc """
  Administrative conveniences to modify aggregates
  """
  import Ecto.Query

  def create(name, description, tags \\ []) do
    {:ok, constrained} = name |> Exsemantica.Constrain.into_valid_aggregate()

    Exsemantica.Repo.insert(%Exsemantica.Repo.Aggregate{
      name: constrained,
      description: description,
      tags: tags
    })
  end

  def delete(id) do
    Exsemantica.Repo.get(Exsemantica.Repo.Aggregate, id)
    |> Exsemantica.Repo.delete()
  end

  def add_moderators(id, user_ids) do
    Exsemantica.Repo.insert_all(
      "moderators_aggregates",
      user_ids |> Enum.map(&%{aggregate_id: id, user_id: &1})
    )
  end

  def remove_moderators(id, user_ids) do
    Exsemantica.Repo.delete_all(
      from(m in "moderators_aggregates",
        where: m.user_id in ^user_ids and m.aggregate_id == ^id,
        select: %{aggregate_id: m.aggregate_id, user_id: m.user_id}
      )
    )
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

  def set_tags(id, tags) do
    Exsemantica.Repo.get(Exsemantica.Repo.Aggregate, id)
    |> Ecto.Changeset.change(%{tags: tags})
    |> Exsemantica.Repo.update()
  end
end
