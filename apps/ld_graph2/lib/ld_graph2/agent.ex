# Copyright 2020-2021 Roland Metivier
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
defmodule LdGraph2.Agent do
  @moduledoc """
  An agent that manages a graph, allowing key-value databases to be used
  instead of a purposefully-built graph database.

  Note that a few special graph operations like searching are not implemented
  yet.
  """
  use Agent
  require Logger

  # Increment when adding backward-incompatible version changes to the
  # database delta format.
  @curr_db_ver 1

  @spec start_link(atom) :: {:error, any} | {:ok, pid}
  @doc """
  Starts the agent, loading the specified graph off the `LdGraph2`
  application's priv directory.
  """
  def start_link(name) do
    Agent.start_link(fn ->
      store =
        Path.join([
          Application.app_dir(:ld_graph2, "priv"),
          to_string(name) <> ".ld2"
        ])

      {:ok, table} =
        case File.exists?(store) do
          true -> :ets.file2tab(to_charlist(store), [])
          false -> {:ok, :ets.new(name, [:ordered_set, :private])}
        end

      {_, graph} =
        :ets.match_object(table, {:_, :_, :_})
        |> Enum.map(&check_version!/1)
        |> Enum.reduce({table, %LdGraph2.Graph{}}, &apply_delta/2)

      {name, table, graph}
    end)
  end

  @spec get(atom | pid | {atom, any} | {:via, atom, any}) :: any
  @doc """
  Gets the current graph data.
  """
  def get(agent) do
    Agent.get(agent, fn {_name, _table, graph} ->
      graph
    end)
  end

  @spec update(atom | pid | {atom, any} | {:via, atom, any}, any) :: :ok
  @doc """
  Applies a transaction/delta to a `LdGraph2.Graph`, saving to disk.

  ## Examples
  Listed below are a few examples of possible transactions. Each tuple is
  processed left-to-right within the list.

  ```elixir
  [{:add, {:node, 2}}]
  [{:add, {:node, 0}}, {:add, {:node, 1}}, {:add, {:edge, 0, 1}}]
  [{:del, {:edge, 0, 1}}]
  ```
  """
  def update(agent, transactions) do
    Agent.update(agent, fn {name, table, graph} ->
      {_, graph} =
        transactions
        |> Enum.reduce({table, graph}, &apply_delta/2)

      :ets.tab2file(
        table,
        to_charlist(
          Path.join([Application.app_dir(:ld_graph2, "priv"), to_string(name) <> ".ld2"])
        ),
        []
      )

      {name, table, graph}
    end)
  end

  defp check_version!({_index, major, content}) when major === @curr_db_ver do
    content
  end

  defp check_version!({index, major, _content}) do
    raise Version.InvalidVersionError,
          "At graph ETS index #{index}: version '#{major}' isn't the " <>
            "supported version '#{@curr_db_ver}'"
  end

  defp do_predelta(:"$end_of_table"), do: 1
  defp do_predelta(verb), do: verb + 1

  defp apply_delta(delta, {table, graph}) do
    :ets.insert_new(table, {do_predelta(:ets.last(table)), @curr_db_ver, delta})

    {table,
     case delta do
       {:add, what} ->
         case what do
           {:node, at} -> LdGraph2.Graph.put_node(graph, at)
           {:edge, from, to} -> LdGraph2.Graph.put_edge(graph, from, to)
         end

       {:del, what} ->
         case what do
           {:node, at} -> LdGraph2.Graph.del_node(graph, at)
           {:edge, from, to} -> LdGraph2.Graph.del_edge(graph, from, to)
         end
     end}
  end
end
