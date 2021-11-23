defmodule Exsemantica.Schema do
  @moduledoc """
  The ExSemantica GraphQL API schema.
  """
  use Absinthe.Schema

  scalar :id128 do
    description("Unique Identifier (128-bit base64 machine-readable value)")
    parse(&Exsemantica.Id128.parse!(&1))
    serialize(&Exsemantica.Id128.serialize(&1))
  end

  query do
  end
end
