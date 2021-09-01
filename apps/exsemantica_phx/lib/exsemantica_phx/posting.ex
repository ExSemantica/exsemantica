defmodule ExsemanticaPhx.Posting do
  require LdGraph2.Agent

  def new_interest(user, title, content) do
    valid = Regex.match?(~r/[^A-Za-z0-9\_]/, title)

    cond do
      valid ->
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

      true ->
        nil
    end
  end

  def new_user(raw_username, raw_email, hash) do
    email_valid = not Regex.match?(~r/\//, raw_email)

    email_ir0 =
      cond do
        email_valid -> URI.parse("//" <> raw_email)
        true -> nil
      end

    email_valid =
      not (Regex.match?(~r/\@/, email_ir0.userinfo) or
             Regex.match?(~r/\@/, email_ir0.host) or
             String.starts_with?(email_ir0.userinfo, ".") or
             String.ends_with?(email_ir0.userinfo, ".") or
             String.starts_with?(email_ir0.host, ".") or
             String.ends_with?(email_ir0.host, "."))

    username_valid = Regex.match?(~r/[^A-Za-z0-9\_]/, raw_username)

    cond do
      email_valid and username_valid ->
        ExsemanticaPhx.Repo.transaction(fn ->
          max_id = ExsemanticaPhx.Search.max_id() + 1

          ExsemanticaPhx.Repo.insert(%ExsemanticaPhx.Site.User{
            username: String.downcase(raw_username),
            email: raw_email,
            password: hash,
            node_corresponding: max_id
          })

          LdGraph2.Agent.update(ExsemanticaPhx.GraphStore, [
            {:add, {:node, max_id}}
          ])
        end)

      true ->
        nil
    end
  end
end
