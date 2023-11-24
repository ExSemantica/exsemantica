defmodule Exsemantica.RepoCommentTest do
  use Exsemantica.DataCase, async: true
  alias Exsemantica.Repo.User
  alias Exsemantica.Repo.Comment

  setup do
    # We need an author to make comments.
    {:ok, user} =
      Exsemantica.Repo.insert(%User{
        username: "Test_User",
        password: "test_password",
        biography: "Test Biography",
        email: "test_user@example.com"
      })

    [user: user]
  end

  test "traverses a comment chain", %{user: user} do
    # Root comment
    {:ok, comment} =
      Exsemantica.Repo.insert(%Comment{
        hidden: false,
        contents: "First comment",
        user_id: user.id
      })

    # =========================================================================
    # Reply once
    {:ok, reply0} =
      Ecto.build_assoc(comment, :replies)
      |> Ecto.Changeset.change(%{
        hidden: false,
        contents: "First reply!",
        user_id: user.id
      })
      |> Exsemantica.Repo.insert()

    # Reply again
    {:ok, reply1} =
      Ecto.build_assoc(comment, :replies)
      |> Ecto.Changeset.change(%{
        hidden: false,
        contents: "Second reply!",
        user_id: user.id
      })
      |> Exsemantica.Repo.insert()

    # =========================================================================
    # Ecto needs to preload our replies
    comment_preloaded = comment |> Exsemantica.Repo.preload([:replies])

    # Do comments have replies?
    assert %{comment | replies: [reply0, reply1]} == comment_preloaded

    # =========================================================================
    # Ecto needs to preload our parent
    reply0_preloaded = reply0 |> Exsemantica.Repo.preload([:parent])

    # Does a reply have a parent?
    assert reply0_preloaded.parent_id == comment.id
  end

  test "add votes to comments", %{user: user} do
    # We need test users to upvote
    upvoters =
      1..700
      |> Enum.map(
        &(%Exsemantica.Repo.User{
            username: "Voter_#{&1}",
            password: "test_password",
            biography: "Test Biography",
            email: "test_voter#{&1}@example.com"
          }
          |> Exsemantica.Repo.insert())
      )

    # Some others to downvote
    downvoters =
      701..1000
      |> Enum.map(
        &(%Exsemantica.Repo.User{
            username: "Voter_#{&1}",
            password: "test_password",
            biography: "Test Biography",
            email: "test_voter#{&1}@example.com"
          }
          |> Exsemantica.Repo.insert())
      )

    # =========================================================================
    # Root comment
    {:ok, comment} =
      Exsemantica.Repo.insert(%Comment{
        hidden: false,
        contents: "First comment",
        user_id: user.id
      })

    # Upvote
    for {:ok, upvoter} <- upvoters do
      comment
      |> Ecto.build_assoc(:votes)
      |> Ecto.Changeset.change(%{user_id: upvoter.id})
      |> Exsemantica.Repo.insert()
    end

    # Downvotes happen less, let's make them forced to be define explicitly
    for {:ok, downvoter} <- downvoters do
      comment
      |> Ecto.build_assoc(:votes)
      |> Ecto.Changeset.change(%{user_id: downvoter.id, is_downvote: true})
      |> Exsemantica.Repo.insert()
    end

    # =========================================================================
    # Preload votes
    comment_preloaded = comment |> Exsemantica.Repo.preload([:votes])

    # Upvotes subtract downvotes

    score =
      comment_preloaded.votes
      |> Enum.reduce(
        0,
        fn vote, count ->
          if vote.is_downvote, do: count - 1, else: count + 1
        end
      )

    # Check precalculated upvoters and downvoters
    assert score == length(upvoters) - length(downvoters)
  end
end
