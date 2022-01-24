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
defmodule Exsemtheme.Client do
  @moduledoc """
  HTTP GraphQL Client
  """
  def fetch_trending(fields, count) do
    {:ok, reply} =
      Finch.build(
        :post,
        Application.fetch_env!(:exsemtheme, :api),
        [
          {"content-type", "application/graphql"}
        ],
        "{ trending(count: #{count}) { #{fields |> Enum.join(",")} } }"
      )
      |> Finch.request(Exsemtheme.Client.Finch)

    {:ok, data} = reply.body |> Jason.decode()

    data |> get_in(~w(data trending))
  end

  def fetch_users(fields, rids), do: fetch(:users, fields, rids)
  def fetch_posts(fields, rids), do: fetch(:posts, fields, rids)
  def fetch_interests(fields, rids), do: fetch(:interests, fields, rids)

  defp fetch(type, fields, rids) do
    ids = rids |> Enum.map(&"\"#{&1}\"") |> Enum.join(",")

    {:ok, reply} =
      Finch.build(
        :post,
        Application.fetch_env!(:exsemtheme, :api),
        [
          {"content-type", "application/graphql"}
        ],
        "{ #{type}(ids: [#{ids}]) { #{fields |> Enum.join(",")} } }"
      )
      |> Finch.request(Exsemtheme.Client.Finch)

      {:ok, data} = reply.body |> Jason.decode()

      data |> get_in(~w(data #{type}))
  end
end
