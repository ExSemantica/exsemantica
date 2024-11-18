defmodule Exsemantica.Schema do
  alias Exsemantica.Repo
  use Absinthe.Schema
  import Ecto.Query

  import_types(__MODULE__.Types)

  query do
    field :aggregate, :aggregate do
      arg(:id, :id)
      arg(:name, :string)

      resolve(fn args, _info ->
        aggregate =
          case args do
            %{id: id} ->
              Repo.one(from(a in Repo.Aggregate, where: a.id == ^id, select: a))

            %{name: name} ->
              Repo.one(from(a in Repo.Aggregate, where: ilike(a.name, ^name), select: a))
          end

        if is_nil(aggregate) do
          {:ok, %{}}
        else
          {:ok,
           %{
             id: aggregate.id,
             name: aggregate.name,
             description: aggregate.description,
             tags: aggregate.tags,
             moderators: aggregate.moderators,
             posts: aggregate.posts,
             created_on: aggregate.inserted_at
           }}
        end
      end)
    end

    field :user, :user do
      arg(:id, :id)
      arg(:name, :string)

      resolve(fn args, _info ->
        user =
          case args do
            %{id: id} ->
              Repo.one(from(u in Repo.User, where: u.id == ^id, select: u))

            %{handle: handle} ->
              Repo.one(from(u in Repo.User, where: ilike(u.handle, ^handle), select: u))
          end

        if is_nil(user) do
          {:ok, %{}}
        else
          {:ok,
           %{
             id: user.id,
             handle: user.username,
             biography: user.biography,
             moderating: user.aggregates,
             posts: user.posts,
             comments: user.comments,
             created_on: user.inserted_at
           }}
        end
      end)
    end
  end

  subscription do
    field :aggregate_posts, :post do
      arg(:aggregate_id, non_null(:id))

      config(fn args, _info ->
        {:ok, topic: "aggregate/" <> args.aggregate_id}
      end)
    end
  end
end
