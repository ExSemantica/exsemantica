defmodule Exsemantica.Cache.Votes do
  @moduledoc """
  Depends on `Exsemantica.Cache` Mnesia store.

  Utility vote cache modification functions
  """

  @doc """
  Modifies the **cache entry**'s vote post or comment score.

  Set to 0 if not modifying.
  """
  @spec modify({:post | :comment, integer()}, integer()) :: integer()
  def modify(otype_id, delta) do
    {:atomic, {Exsemantica.Cache.Vote, ^otype_id, _num_votes}} =
      :mnesia.transaction(fn ->
        {:atomic, retrieved_votes} =
          :mnesia.index_read(Exsemantica.Cache.Vote, otype_id, :otype_id)

        case retrieved_votes do
          [] ->
            votes = load_from_miss(otype_id)
            vote_entry = {Exsemantica.Cache.Vote, otype_id, votes}
            :mnesia.write(vote_entry)
            vote_entry

          [vote_entry] ->
            vote_entry
        end
      end)

    :mnesia.dirty_update_counter(Exsemantica.Cache.Vote, otype_id, delta)
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
