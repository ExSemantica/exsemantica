defmodule ExsemanticaWeb.Schema do
  @moduledoc """
  The ExSemantica GraphQL API schema.
  """
  use Absinthe.Schema

  import_types(ExsemanticaWeb.SchemaTypes)

  query do
    # ==========================================================================
    field :posts, list_of(:post) do
      arg(:ids, list_of(:id128))

      complexity(fn %{ids: ids}, child_complexity ->
        length(ids) * child_complexity
      end)

      resolve(fn %{ids: ids}, _ ->
        {:atomic, packets} =
          ids
          |> Enum.uniq()
          |> Enum.flat_map(
            &[
              Exsemnesia.Utils.increment_popularity(:posts, &1),
              Exsemnesia.Utils.get(:posts, &1)
            ]
          )
          |> Exsemnesia.Database.transaction()

        {:ok,
         packets
         |> Enum.map(fn packet ->
           case packet.response do
             [{:posts, id, timestamp, title, content, posted_by}] ->
               %{
                 node: id,
                 title: title,
                 content: content,
                 posted: posted_by,
                 timestamp: timestamp
               }

             _ ->
               nil
           end
         end)
         |> Enum.reject(&is_nil(&1))}
      end)
    end

    # ==========================================================================
    field :users, list_of(:user) do
      arg(:ids, list_of(:id128))

      complexity(fn %{ids: ids}, child_complexity ->
        length(ids) * child_complexity
      end)

      resolve(fn %{ids: ids}, _ ->
        {:atomic, packets} =
          ids
          |> Enum.uniq()
          |> Enum.flat_map(
            &[
              Exsemnesia.Utils.increment_popularity(:users, &1),
              Exsemnesia.Utils.get(:users, &1)
            ]
          )
          |> Exsemnesia.Database.transaction()

        {:ok,
         packets
         |> Enum.map(fn packet ->
           case packet.response do
             [{:users, id, timestamp, handle, privmask}] ->
               %{
                 node: id,
                 handle: handle,
                 timestamp: timestamp,
                 privmask: Base.encode16(privmask)
               }

             _ ->
               nil
           end
         end)
         |> Enum.reject(&is_nil(&1))}
      end)
    end

    # ==========================================================================
    field :interests, list_of(:interest) do
      arg(:ids, list_of(:id128))

      complexity(fn %{ids: ids}, child_complexity ->
        length(ids) * child_complexity
      end)

      resolve(fn %{ids: ids}, _ ->
        {:atomic, packets} =
          ids
          |> Enum.uniq()
          |> Enum.flat_map(
            &[
              Exsemnesia.Utils.increment_popularity(:interests, &1),
              Exsemnesia.Utils.get(:interests, &1)
            ]
          )
          |> Exsemnesia.Database.transaction()

        {:ok,
         packets
         |> Enum.map(fn packet ->
           case packet.response do
             [{:interests, id, timestamp, title, content, related_to}] ->
               %{
                 node: id,
                 title: title,
                 content: content,
                 related: related_to,
                 timestamp: timestamp
               }

             _ ->
               nil
           end
         end)
         |> Enum.reject(&is_nil(&1))}
      end)
    end

    # ==========================================================================
    field :trending, list_of(:trend) do
      arg(:count, :integer)
      arg(:fuzzy, :string)

      complexity(fn %{count: count, fuzzy: _}, child_complexity ->
        count * child_complexity
      end)

      resolve(fn %{count: count, fuzzy: fuzzy_handle}, _ when count > 0 ->
        {:atomic, [packet]} =
          [Exsemnesia.Utils.trending(count)]
          |> Exsemnesia.Database.transaction()

        {:ok,
         if not is_nil(fuzzy_handle) do
           Enum.reverse(
             for resp <- packet.response do
               {:ctrending, _, id, type, _, handle} = resp

               %{
                 node: id,
                 type: type,
                 handle: handle,
                 relevance:
                   String.bag_distance(
                     String.downcase(handle, :ascii),
                     String.downcase(fuzzy_handle, :ascii)
                   )
               }
             end
           )
         else
           Enum.reverse(
             for resp <- packet.response do
               {:ctrending, _, id, type, _, handle} = resp

               %{
                 node: id,
                 type: type,
                 handle: handle,
                 relevance: 1.0
               }
             end
           )
         end}
      end)
    end
  end
end
