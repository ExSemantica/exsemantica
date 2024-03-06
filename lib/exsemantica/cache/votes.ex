defmodule Exsemantica.Cache.Votes do
  @moduledoc """
  Depends on `Exsemantica.Cache` Mnesia store.

  Utility vote cache modification functions.
  """

  require Logger

  @spec modify({{:post | :comment, integer()}, integer()}) :: {:ok, integer()}
  @doc """
  Modifies the **cache entry**'s vote post or comment score.
  """
  def modify({otype_id, delta}) do
    Logger.debug("Modify #{inspect(otype_id)} by #{inspect(delta)}")

    {:ok, votes} = load(otype_id)

    votes = votes + delta

    {:atomic, :ok} =
      :mnesia.transaction(fn ->
        :ok = :mnesia.write({Exsemantica.Cache.Vote, otype_id, votes})
      end)

    {:ok, votes}
  end

  @spec load({:post | :comment, integer()}) :: {:ok, integer()}
  @doc """
  Loads the **cache entry**'s vote post or comment score.
  """
  def load(otype_id) do
    {:atomic, {Exsemantica.Cache.Vote, ^otype_id, votes}} =
      :mnesia.transaction(fn ->
        cached_vote_hit = :mnesia.read(Exsemantica.Cache.Vote, otype_id)

        case cached_vote_hit do
          [vote_entry] ->
            Logger.debug("Load #{inspect(otype_id)} CACHE HIT")
            vote_entry

          [] ->
            Logger.debug("Load #{inspect(otype_id)} CACHE MISS")
            votes = load_from_miss(otype_id)
            vote_entry = {Exsemantica.Cache.Vote, otype_id, votes}
            :ok = :mnesia.write(vote_entry)
            vote_entry
        end
      end)

    {:ok, votes}
  end

  # Stuff to load from a cache miss
  # TODO: Test cases!
  defp load_from_miss({:comment, id}) do
    Exsemantica.Repo.get(Exsemantica.Repo.Comment, id)
    |> Exsemantica.Repo.preload([:votes])
    |> Map.get(:votes)
    |> Enum.reduce(
      0,
      fn vote, count ->
        if vote.is_downvote, do: count - 1, else: count + 1
      end
    )
  end

  defp load_from_miss({:post, id}) do
    Exsemantica.Repo.get(Exsemantica.Repo.Post, id)
    |> Exsemantica.Repo.preload([:votes])
    |> Map.get(:votes)
    |> Enum.reduce(
      0,
      fn vote, count ->
        if vote.is_downvote, do: count - 1, else: count + 1
      end
    )
  end
end
