defmodule Exsemantica.Administration.Post do
  @moduledoc """
  Administrative conveniences to modify posts
  """
  def create_self(aggregate_id, user_id, title, contents, tags \\ []) do
    # Two-way association will use this trick
    # https://stackoverflow.com/questions/42755269/ecto-build-multiple-assoc
    Exsemantica.Repo.get(Exsemantica.Repo.Aggregate, aggregate_id)
    |> Ecto.build_assoc(:posts)
    |> Ecto.Changeset.change(%{
      type: :self,
      title: title,
      contents: contents,
      tags: tags
    })
    |> Ecto.Changeset.put_assoc(:user, Exsemantica.Repo.get(Exsemantica.Repo.User, user_id))
    |> Exsemantica.Repo.insert()
  end

  def create_link(aggregate_id, user_id, title, contents, tags \\ []) do
    # Two-way association will use this trick
    # https://stackoverflow.com/questions/42755269/ecto-build-multiple-assoc
    Exsemantica.Repo.get(Exsemantica.Repo.Aggregate, aggregate_id)
    |> Ecto.build_assoc(:posts)
    |> Ecto.Changeset.change(%{
      type: :link,
      title: title,
      contents: contents,
      tags: tags
    })
    |> Ecto.Changeset.put_assoc(:user, Exsemantica.Repo.get(Exsemantica.Repo.User, user_id))
    |> Exsemantica.Repo.insert()
  end

  def delete(id) do
    Exsemantica.Repo.get(Exsemantica.Repo.Post, id)
    |> Exsemantica.Repo.delete()
  end

  def set_hidden(id, hidden) do
    Exsemantica.Repo.get(Exsemantica.Repo.Post, id)
    |> Ecto.Changeset.change(%{hidden: hidden})
    |> Exsemantica.Repo.update()
  end

  def set_contents(id, contents) do
    Exsemantica.Repo.get(Exsemantica.Repo.Post, id)
    |> Ecto.Changeset.change(%{contents: contents})
    |> Exsemantica.Repo.update()
  end

  def set_tags(id, tags) do
    Exsemantica.Repo.get(Exsemantica.Repo.Post, id)
    |> Ecto.Changeset.change(%{tags: tags})
    |> Exsemantica.Repo.update()
  end
end
