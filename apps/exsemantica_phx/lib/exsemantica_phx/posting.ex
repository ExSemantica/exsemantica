defmodule ExsemanticaPhx.Posting do
  require LdGraph2.Agent

  def new_interest(user, title, content) do
    ExsemanticaPhx.Repo.transaction(fn ->
      max_id = ExsemanticaPhx.Search.max_id() + 1
      ExsemanticaPhx.Repo.insert(%ExsemanticaPhx.Site.Post{
        content: content,
        title: title,
        is_interest: true,
        node_corresponding: max_id,
        poster: user
      })
      LdGraph2.Agent.update(ExsemanticaPhx.GraphStore, [
        {:add, {:node, max_id}},
        {:add, {:edge, user, max_id}}
      ])
    end)
  end

  def new_user(username, _password) do
    ExsemanticaPhx.Repo.transaction(fn ->
      max_id = ExsemanticaPhx.Search.max_id() + 1
      ExsemanticaPhx.Repo.insert(%ExsemanticaPhx.Site.User{
        username: username,
        password: "00",
        node_corresponding: max_id,
      })
      LdGraph2.Agent.update(ExsemanticaPhx.GraphStore, [
        {:add, {:node, max_id}},
      ])
    end)
  end
end
