defmodule Exsemantica.Admin.User do
  @moduledoc """
  Administrative conveniences to modify users
  """
  def create(username, password, email, biography) do
    {:ok, constrained} = username |> Exsemantica.Constrain.into_valid_username()

    Exsemantica.Repo.insert(%Exsemantica.Repo.User{
      username: constrained,
      password: Argon2.hash_pwd_salt(password),
      email: email,
      biography: biography
    })
  end

  def delete(id) do
    Exsemantica.Repo.get(Exsemantica.Repo.User, id)
    |> Exsemantica.Repo.delete()
  end

  def set_hidden(id, hidden) do
    Exsemantica.Repo.get(Exsemantica.Repo.User, id)
    |> Ecto.Changeset.change(%{hidden: hidden})
    |> Exsemantica.Repo.update()
  end

  def set_biography(id, biography) do
    Exsemantica.Repo.get(Exsemantica.Repo.User, id)
    |> Ecto.Changeset.change(%{biography: biography})
    |> Exsemantica.Repo.update()
  end
end
