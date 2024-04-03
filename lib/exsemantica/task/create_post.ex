defmodule Exsemantica.Task.CreatePost do
  @moduledoc """
  A task that creates a post in an aggregate
  """
  @behaviour Exsemantica.Task

  @impl true
  def run(%{
        user_id: user_id,
        aggregate_id: aggregate_id,
        post_data: post_data
      }) do
    valid? =
      if post_data.type == :link do
        uri = URI.parse(post_data.contents)
        uri.scheme != nil && uri.host =~ "."
      else
        true
      end

    if valid? do
      Exsemantica.Repo.get(Exsemantica.Repo.Aggregate, aggregate_id)
      |> Ecto.build_assoc(:posts)
      |> Ecto.Changeset.change(post_data)
      |> Ecto.Changeset.put_assoc(:user, Exsemantica.Repo.get(Exsemantica.Repo.User, user_id))
      |> Exsemantica.Repo.insert()
    else
      {:error, :invalid}
    end
  end
end
