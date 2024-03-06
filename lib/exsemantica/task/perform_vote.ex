defmodule Exsemantica.Task.PerformVote do
  @moduledoc """
  A task that performs an upvote or a downvote on either a post or a comment
  """
  @behaviour Exsemantica.Task

  @impl true
  def run(%{id: id, user_id: user_id, type: :post, vote_type: type}) do
    data =
      Exsemantica.Repo.get(Exsemantica.Repo.Post, id)

    case data do
      # Couldn't find the post
      nil ->
        :not_found

      # Load the post
      post ->
        post_preloaded = post |> Exsemantica.Repo.preload([:votes])

        vote =
          post_preloaded.votes
          |> Enum.find(fn vote ->
            vote.user_id == user_id
          end)

        # Do SQL and then cache
        case vote do
          nil when type == :upvote ->
            post
            |> Ecto.build_assoc(:votes)
            |> Ecto.Changeset.change(%{user_id: user_id, is_downvote: false})
            |> Exsemantica.Repo.insert()

            Exsemantica.Cache.adjust_vote({:post, id}, 1)

          nil when type == :downvote ->
            post
            |> Ecto.build_assoc(:votes)
            |> Ecto.Changeset.change(%{user_id: user_id, is_downvote: true})
            |> Exsemantica.Repo.insert()

            Exsemantica.Cache.adjust_vote({:post, id}, -1)

          _non_nil_vote ->
            vote
            |> Exsemantica.Repo.delete()

            if vote.is_downvote do
              Exsemantica.Cache.adjust_vote({:post, id}, 1)
            else
              Exsemantica.Cache.adjust_vote({:post, id}, -1)
            end
        end
    end
  end

  def run(%{id: id, user_id: user_id, type: :comment, vote_type: type}) do
    data =
      Exsemantica.Repo.get(Exsemantica.Repo.Comment, id)

    case data do
      # Couldn't find the post
      nil ->
        :not_found

      # Load the post
      comment ->
        comment_preloaded = comment |> Exsemantica.Repo.preload([:votes])

        vote =
          comment_preloaded.votes
          |> Enum.find(fn vote ->
            vote.user_id == user_id
          end)

        # Do SQL and then cache
        case vote do
          nil when type == :upvote ->
            comment
            |> Ecto.build_assoc(:votes)
            |> Ecto.Changeset.change(%{user_id: user_id, is_downvote: false})
            |> Exsemantica.Repo.insert()

            Exsemantica.Cache.adjust_vote({:comment, id}, 1)

          nil when type == :downvote ->
            comment
            |> Ecto.build_assoc(:votes)
            |> Ecto.Changeset.change(%{user_id: user_id, is_downvote: true})
            |> Exsemantica.Repo.insert()

            Exsemantica.Cache.adjust_vote({:comment, id}, -1)

          _non_nil_vote ->
            vote
            |> Exsemantica.Repo.delete()

            if vote.is_downvote do
              Exsemantica.Cache.adjust_vote({:comment, id}, 1)
            else
              Exsemantica.Cache.adjust_vote({:comment, id}, -1)
            end
        end
    end
  end
end
