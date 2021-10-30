defmodule ExsemanticaPhx.Protect do
  import Ecto.Query

  @paranoia 4096

  def create_contract(username) do
    user_struct =
      ExsemanticaPhx.Repo.one(
        from(u in ExsemanticaPhx.Site.User, where: u.username == ^username and is_nil(u.contract))
      )

    cond do
      is_nil(user_struct) ->
        {:error, :enoent}

      true ->
        jwk = JOSE.JWK.generate_key({:rsa, @paranoia})

        {_kty, bin} = JOSE.JWK.to_der(jwk)

        Ecto.Changeset.change(user_struct, %{contract: bin})
        |> ExsemanticaPhx.Repo.update()

        {:ok, jwk |> JOSE.JWK.to_public()}
    end
  end

  def remove_contract(username) do
    user_struct =
      ExsemanticaPhx.Repo.one(
        from(u in ExsemanticaPhx.Site.User,
          where: u.username == ^username and not is_nil(u.contract)
        )
      )

    cond do
      is_nil(user_struct) ->
        {:error, :enoent}

      true ->
        Ecto.Changeset.change(user_struct, %{contract: nil})
        |> ExsemanticaPhx.Repo.update()
        :ok
    end
  end

  def find_user(username) do
    ExsemanticaPhx.Repo.one(from(u in ExsemanticaPhx.Site.User, where: u.username == ^username))
  end

  def find_contract(user) when not is_nil(user.contract) do
    {%{kty: :jose_jwk_kty_rsa}, user.contract}
    |> JOSE.JWK.from_der()
    |> JOSE.JWK.to_public()
  end

  def find_contract(_user), do: nil
end
