defmodule Exsemantica.Schema.Types do
  use Absinthe.Schema.Notation

  scalar :id128 do
    description("Unique Identifier (128-bit base64 machine-readable value)")
    parse(&Exsemantica.Id128.parse/1)
    serialize(&Exsemantica.Id128.serialize/1)
  end

  scalar :handle128 do
    description("Handle (15-char string value)")
    parse(&Exsemantica.Handle128.parse/1)
    serialize(&Exsemantica.Handle128.serialize/1)
  end
  # ============================================================================
  # User data
  # ============================================================================
  object :user do
    field :node, :id128
    field :handle, :handle128
    field :biography, :string
  end

  object :user_rframe do
    field :user, :user
    field :email, :string
  end
  # ============================================================================
  # Post data
  # ============================================================================
  # ============================================================================
  # Interest data
  # ============================================================================
end
