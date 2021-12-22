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

  @spec start_link(list) :: {:error, any} | {:ok, pid}
  @doc """
  Starts the agent, loading the specified graph off a Redis store.
  """
  def start_link(kvstore_name: name, opts: opts) do
    Agent.start_link(
      fn ->
        lname = "ld2." <> name

        {:ok, llength} =
          Redix.command(LdGraph2.Redix, [
            "LLEN",
            lname
          ])

        {:ok, version_etf} = Redix.command(LdGraph2.Redix, ["GET", lname <> ".delta_versions"])

        {lname,
         if version_etf do
           version = check_version(:erlang.binary_to_term(version_etf, [:safe]))

           cond do
             llength < 1 ->
               # Of course Redix can't handle null queries.
               # Why would you do a query like that?
               %LdGraph2.Graph{}

             version ->
               {:ok, raw_graph} =
                 Redix.transaction_pipeline(
                   LdGraph2.Redix,
                   Stream.repeatedly(fn ->
                     [
                       "LMOVE",
                       lname,
                       lname,
                       "LEFT",
                       "RIGHT"
                     ]
                   end)
                   |> Enum.take(llength)
                 )

               raw_graph
               |> Stream.map(&:erlang.binary_to_term(&1, [:safe]))
               |> Enum.reduce(%LdGraph2.Graph{}, &apply_delta/2)

             true ->
               raise Version.InvalidVersionError,
                     "Graph cache delta version isn't the " <>
                       "supported version '#{@curr_db_ver}'"
           end
         else
           Redix.command(LdGraph2.Redix, [
             "SET",
             lname <> ".delta_versions",
             :erlang.term_to_binary(@curr_db_ver)
           ])

           %LdGraph2.Graph{}
         end}
      end,
      opts
    )
  end

  @spec get(atom | pid | {atom, any} | {:via, atom, any}) :: any
  @doc """
  Gets the current graph data.
  """
  def get(agent) do
    Agent.get(agent, fn {_name, graph} ->
      graph
    end)
  end

  @spec update(atom | pid | {atom, any} | {:via, atom, any}, any) :: :ok
  @doc """
  Applies a transaction/delta to a `LdGraph2.Graph`, saving to Redis.

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
    Agent.update(agent, fn {name, graph} ->
      Redix.command(
        LdGraph2.Redix,
        List.flatten([
          "RPUSH",
          name,
          transactions
          |> Enum.map(&:erlang.term_to_binary/1)
        ])
      )

      {name,
       transactions
       |> Enum.reduce(graph, &apply_delta/2)}
    end)
  end

  defp check_version(major) when major === @curr_db_ver do
    true
  end

  defp check_version(major) do
    Logger.error(
      "LdGraph2 delta storage encoder #{major} isn't supported. Yours is #{@curr_db_ver}."
    )

    false
  end

  defp apply_delta(delta, graph) do
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
    end
  end
end
