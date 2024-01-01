defmodule Exsemantica.Admin.Post do
  @moduledoc """
  Administrative conveniences to modify posts
  """
  def create_self(aggregate_id, user_id, title, contents) do
    # Two-way association will use this trick
    # https://stackoverflow.com/questions/42755269/ecto-build-multiple-assoc
    {:ok, post} =
      Exsemantica.Repo.get(Exsemantica.Repo.Aggregate, aggregate_id)
      |> Ecto.build_assoc(:posts)
      |> Ecto.Changeset.change(%{
        type: :self,
        title: title,
        contents: contents
      })
      |> Ecto.Changeset.put_assoc(:user, Exsemantica.Repo.get(Exsemantica.Repo.User, user_id))
      |> Exsemantica.Repo.insert()

    ExsemanticaWeb.Endpoint.broadcast("post", "refresh", %{
      id: post.id,
      hints: %{aggregate: aggregate_id, user: user_id}
    })

    :ok
  end

  def create_link(aggregate_id, user_id, title, contents) do
    # Two-way association will use this trick
    # https://stackoverflow.com/questions/42755269/ecto-build-multiple-assoc
    {:ok, post} = Exsemantica.Repo.get(Exsemantica.Repo.Aggregate, aggregate_id)
    |> Ecto.build_assoc(:posts)
    |> Ecto.Changeset.change(%{
      type: :link,
      title: title,
      contents: contents
    })
    |> Ecto.Changeset.put_assoc(:user, Exsemantica.Repo.get(Exsemantica.Repo.User, user_id))
    |> Exsemantica.Repo.insert()

    ExsemanticaWeb.Endpoint.broadcast("post", "refresh", %{
      id: post.id,
      hints: %{aggregate: aggregate_id, user: user_id}
    })

    :ok
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
end
