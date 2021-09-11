defmodule ExsemanticaPhx.Posting do
  require LdGraph2.Agent
  import Ecto.Query

  def new_interest(user, title, content) do
    valid = ExsemanticaPhx.Sanitize.valid_interest(title)

    cond do
      valid ->
        max_id = ExsemanticaPhx.Search.max_id() + 1

        {:ok, _} =
          ExsemanticaPhx.Repo.transaction(fn ->
            response = ExsemanticaPhx.Repo.insert(%ExsemanticaPhx.Site.Post{
              content: content,
              title: title,
              is_interest: true,
              node_corresponding: max_id,
              poster: user
            })

            :ok = LdGraph2.Agent.update(ExsemanticaPhx.GraphStore, [
              {:add, {:node, max_id}},
              {:add, {:edge, user, max_id}}
            ])

            response
          end)

        {:ok, max_id}

      true ->
        nil
    end
  end

  def update_bio(user_nodeid, biography) do
    ExsemanticaPhx.Repo.one(
      from(u in ExsemanticaPhx.Site.User, where: u.node_corresponding == ^user_nodeid)
    )
    |> Ecto.Changeset.change(biography: biography)
    |> ExsemanticaPhx.Repo.update()
  end

  def update_interest(post_nodeid, interest_text) do
    ExsemanticaPhx.Repo.one(
      from(p in ExsemanticaPhx.Site.Post,
        where: p.node_corresponding == ^post_nodeid and p.is_interest
      )
    )
    |> Ecto.Changeset.change(content: interest_text)
    |> ExsemanticaPhx.Repo.update()
  end

  @doc """
  Add a user without an e-mail and password. They are only for testing.

  Not to be used in production.
  """
  def new_test_user(raw_username) do
    username_valid = ExsemanticaPhx.Sanitize.valid_username(raw_username)

    if username_valid do
      max_id = ExsemanticaPhx.Search.max_id() + 1

      {:ok, _} =
        ExsemanticaPhx.Repo.transaction(fn ->
          response = ExsemanticaPhx.Repo.insert(%ExsemanticaPhx.Site.User{
            username: String.downcase(raw_username),
            biography: "",
            node_corresponding: max_id
          })

          :ok = LdGraph2.Agent.update(ExsemanticaPhx.GraphStore, [
            {:add, {:node, max_id}}
          ])

          response
        end)

      {:ok, max_id}
    end
  end

  @doc """
  Add a user with an e-mail and password.

  This is production-called code, and may send network activity. Not to be used
  in testing/dev.
  """
  def new_user(raw_username, raw_email, hash) do
    email_valid = ExsemanticaPhx.Sanitize.valid_email(raw_email)
    username_valid = ExsemanticaPhx.Sanitize.valid_username(raw_username)

    cond do
      email_valid and username_valid ->
        max_id = ExsemanticaPhx.Search.max_id() + 1

        {:ok, _} =
          ExsemanticaPhx.Repo.transaction(fn ->
            response = ExsemanticaPhx.Repo.insert(%ExsemanticaPhx.Site.User{
              username: String.downcase(raw_username),
              email: raw_email,
              password: hash,
              node_corresponding: max_id
            })

            :ok = LdGraph2.Agent.update(ExsemanticaPhx.GraphStore, [
              {:add, {:node, max_id}}
            ])

            response
          end)

        {:ok, max_id}

      true ->
        nil
    end
  end
end
