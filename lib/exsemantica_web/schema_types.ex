defmodule ExsemanticaWeb.SchemaTypes do
  use Absinthe.Schema.Notation

  import_types Absinthe.Type.Custom

  scalar :id128 do
    description("Unique Identifier (128-bit base64 machine-readable value)")
    parse(&Exsemnesia.Id128.parse/1)
    serialize(&Exsemnesia.Id128.serialize/1)
  end

  scalar :handle128 do
    description("Handle (16-char string value)")
    parse(&Exsemnesia.Handle128.parse/1)
    serialize(&Exsemnesia.Handle128.serialize/1)
  end

  object :trend do
    field(:node, :id128)
    field(:type, :string)
    field(:handle, :handle128)
    field(:relevance, :float)
  end

  # ============================================================================
  # User data
  # ============================================================================
  object :user do
    field(:node, :id128)
    field(:handle, :handle128)
    field(:privmask, :string)
    field(:timestamp, :datetime)
  end

  # ============================================================================
  # Post data
  # ============================================================================
  object :post do
    field(:node, :id128)
    field(:title, :string)
    field(:content, :string)
    field(:posted, :id128)
    field(:timestamp, :datetime)
  end

  # ============================================================================
  # Interest data
  # ============================================================================
  object :interest do
    field(:node, :id128)
    field(:title, :string)
    field(:content, :string)
    field(:related, list_of(:id128))
    field(:timestamp, :datetime)
  end
end
