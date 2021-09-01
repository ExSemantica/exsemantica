defmodule ExsemanticaPhx.JwtConfig do
  use Joken.Config

  def token_config do
    default_claims(skip: [:exp, :iss, :nbf, :aud])
    # Expires in 5mins
    |> add_claim("exp", nil, &(&1 > Joken.current_time()))
    # ExSemantica's token
    |> add_claim("iss", fn -> "ExSemantica" end, &(&1 == "ExSemantica"))

    # Crude rate limiting: Limit to an interval in the future
    |> add_claim("nbf", nil, &(&1 <= Joken.current_time()))

    # Audience
    |> add_claim("aud", nil, &(&1 == &2["aud"]))
  end
end
