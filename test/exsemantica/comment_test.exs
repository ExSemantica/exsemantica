defmodule Exsemantica.CommentTest do
  use Exsemantica.DataCase, async: true
  alias Exsemantica.User
  alias Exsemantica.Comment

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
end
