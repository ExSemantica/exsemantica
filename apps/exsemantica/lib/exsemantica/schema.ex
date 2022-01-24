# Copyright 2019-2022 Roland Metivier
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
defmodule Exsemantica.Schema do
  @moduledoc """
  The ExSemantica GraphQL API schema.
  """
  use Absinthe.Schema

  import_types(Exsemantica.Schema.Types)

  query do
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
              Exsemantica.Database.Utils.increment_popularity(:posts, &1),
              Exsemantica.Database.Utils.get(:posts, &1)
            ]
          )
          |> Exsemantica.Database.transaction()

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
              Exsemantica.Database.Utils.increment_popularity(:users, &1),
              Exsemantica.Database.Utils.get(:users, &1)
            ]
          )
          |> Exsemantica.Database.transaction()

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
              Exsemantica.Database.Utils.increment_popularity(:interests, &1),
              Exsemantica.Database.Utils.get(:interests, &1)
            ]
          )
          |> Exsemantica.Database.transaction()

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

    field :trending, list_of(:trend) do
      arg(:count, :integer)

      complexity(fn %{count: count}, child_complexity ->
        count * child_complexity
      end)

      resolve(fn %{count: count}, _ ->
        {:atomic, [packet]} =
          [Exsemantica.Database.Utils.trending(count)]
          |> Exsemantica.Database.transaction()

        {:ok,
         Enum.reverse(
           for resp <- packet.response do
             {:ctrending, _, id, type, _} = resp
             %{node: id, type: type}
           end
         )}
      end)
    end
  end
end
