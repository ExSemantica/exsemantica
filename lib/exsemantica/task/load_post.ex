defmodule Exsemantica.Task.LoadPost do
  @moduledoc """
  A task that loads an aggregate page's data
  """
  @fetches ~w(comments vote_sum)a
  @behaviour Exsemantica.Task
  import Ecto.Query

  @impl true
  def run(%{id: id, aggregate_id: aggregate_id, fetch?: wanted_fetches} = args) do
    data = Exsemantica.Repo.get(Exsemantica.Repo.Post, id)

    case data do
      # Couldn't find the post
      nil ->
        :not_found

      # Load the post
      post when post.aggregate_id == aggregate_id ->
        %{
          post: post,
          info:
            @fetches
            |> Enum.filter(fn match ->
              match in wanted_fetches
            end)
            |> Enum.map(fn fmatch -> fetch(fmatch, id, args) end)
            |> Map.new()
        }

      # Aggregate did not match the one from the post
      _post ->
        :no_match
    end
  end

  defp fetch(:comments, id, _args) do
    # TODO: Calling this function is expensive.                                               c
    {:comments,
     contents:
       Exsemantica.Repo.all(
         from p in Exsemantica.Repo.Post,
           where: p.id == ^id,
           preload: [:comments],
           select: p.comments
       )}
  end

  defp fetch(:vote_sum, id, _args) do
    preload =
      Exsemantica.Repo.one(
        from p in Exsemantica.Repo.Post, where: p.id == ^id, select: p, preload: [:votes]
      )

    {:vote_sum,
     contents:
       preload.votes
       |> Enum.reduce(0, fn vote, count ->
         if vote.is_downvote, do: count - 1, else: count + 1
       end)}
  end
end
