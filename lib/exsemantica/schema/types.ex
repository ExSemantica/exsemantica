defmodule Exsemantica.Schema.Types do
  use Absinthe.Schema.Notation
  import_types Absinthe.Type.Custom

  enum :post_type do
    value :self
    value :link
  end

  object :post do
    field :id, :id
    field :poster, :id
    field :karma, :integer
    field :posted_on, :datetime
    field :edited_on, :datetime

    field :type, :post_type
    field :title, :string
    field :contents, :string
    field :comments, list_of(:comment)
  end

  object :comment do
    field :id, :id
    field :poster, :id
    field :karma, :integer
    field :posted_on, :datetime
    field :edited_on, :datetime

    field :contents, :string
    field :replies, list_of(:comment)
  end

  object :aggregate do
    field :id, :id
    field :name, :string
    field :description, :string
    field :tags, list_of(:string)
    field :created_on, :datetime

    field :posts, list_of(:post)
    field :moderators, list_of(:user)
  end

  object :user do
    field :id, :id
    field :handle, :string
    field :biography, :string
    field :created_on, :datetime

    field :posts, list_of(:post)
    field :comments, list_of(:comment)
    field :moderating, list_of(:aggregate)
  end
end
