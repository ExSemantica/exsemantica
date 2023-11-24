defmodule Exsemantica.RepoAggregateTest do
  use Exsemantica.DataCase, async: true
  alias Exsemantica.Repo.Aggregate
  alias Exsemantica.Repo.User

  setup do
    # We need an author to make comments.
    {:ok, user} =
      Exsemantica.Repo.insert(%User{
        username: "Test_User",
        password: "test_password",
        biography: "Test Biography",
        email: "test_user@example.com"
      })

    {:ok, aggregate} =
      Exsemantica.Repo.insert(%Aggregate{
        name: "test_agg",
        description: "Test Aggregate"
      })

    [user: user, aggregate: aggregate]
  end

  test "allows post insertion in bulk", %{user: user, aggregate: aggregate} do
    # Create a few entries
    entries = 1..250 |> Enum.map(& %{type: :self, title: "Test post #{&1}", contents: "Just testing", user_id: user.id})

    # Insert them
    for entry <- entries do
      aggregate
      |> Ecto.build_assoc(:posts)
      |> Ecto.Changeset.change(entry)
      |> Exsemantica.Repo.insert()
    end

    # Preload them
    aggregate_preloaded = aggregate |> Exsemantica.Repo.preload([:posts])

    # The post-preloaded aggregate should load the entries
    assert length(aggregate_preloaded.posts) == length(entries)
  end
end
