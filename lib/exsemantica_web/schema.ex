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
                 posted_by: posted_by,
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
             [{:users, id, timestamp, handle}] ->
               %{
                 node: id,
                 handle: handle,
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
                 related_to: related_to,
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
      arg(:fuzzy_handle, :string)

      complexity(fn %{count: count}, child_complexity ->
        count * child_complexity
      end)

      complexity(fn %{count: count, fuzzy_handle: _}, child_complexity ->
        count * child_complexity * 2
      end)

      resolve(fn %{count: count}, _ when count > 0 ->
        {:atomic, [packet]} =
          [Exsemnesia.Utils.trending(count)]
          |> Exsemnesia.Database.transaction()

        {:ok,
         Enum.reverse(
           for resp <- packet.response do
             {:ctrending, _, id, type, _, handle} = resp
             %{node: id, type: type, handle: handle, relevance_or_zero: 0.0}
           end
         )}
      end)

      resolve(fn %{count: count, fuzzy_handle: fuzzy_handle}, _ when count > 0 ->
        {:atomic, [packet]} =
          [Exsemnesia.Utils.trending(count)]
          |> Exsemnesia.Database.transaction()

        {:ok,
         Enum.reverse(
           for resp <- packet.response do
             {:ctrending, _, id, type, _, handle} = resp

             %{
               node: id,
               type: type,
               handle: handle,
               relevance_or_zero: String.bag_distance(handle, fuzzy_handle)
             }
           end
         )}
      end)
    end
  end
end
