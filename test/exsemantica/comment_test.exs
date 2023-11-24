defmodule Exsemantica.CommentTest do
  use Exsemantica.DataCase, async: true
  alias Exsemantica.User
  alias Exsemantica.Comment

  test "traverses a comment chain successfully" do
    {:ok, user} = Exsemantica.Repo.insert(%User{
      username: "Test_User",
      password: "test_password",
      biography: "Test Biography",
      email: "test_user@example.com"
    })

    {:ok, comment0} = Exsemantica.Repo.insert(%Comment{
      hidden: false,
      contents: "First comment",
      author: user.id
    })

    {:ok, comment1} = Exsemantica.Repo.insert(%Comment{
      hidden: false,
      contents: "Second comment",
      author: user.id
    })

    comment1 = Comment.changeset(comment0, %{
      parent_id: comment0.id
    })

    Exsemantica.Repo.update(IO.inspect comment1)
    {:ok, comment0} = Exsemantica.Repo.preload(comment0, [:replies])

    IO.inspect comment0
  end
end
