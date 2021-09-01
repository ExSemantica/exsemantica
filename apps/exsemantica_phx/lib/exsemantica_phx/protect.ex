defmodule ExsemanticaPhx.Protect do
  def create_contract(username) do
    user_struct =
      ExsemanticaPhx.Repo.one(%ExsemanticaPhx.Site.User{
        username: username,
        contract: nil
      })

    cond do
      is_nil(user_struct) ->
        nil

      true ->
        jwk = JOSE.JWK.generate_key({:rsa, 4096})

        ExsemanticaPhx.Repo.update(%ExsemanticaPhx.Site.User{
          user_struct
          | contract: JOSE.JWK.to_binary(jwk)
        })

        jwk |> JOSE.JWK.to_public
    end
  end

  def find_user(username) do
    ExsemanticaPhx.Repo.one(%ExsemanticaPhx.Site.User{
      username: username
    })
  end

  def find_contract(user) when not is_nil(user) do
    user.contract
    |> JOSE.JWK.from_binary
    |> JOSE.JWK.to_public
  end
end
