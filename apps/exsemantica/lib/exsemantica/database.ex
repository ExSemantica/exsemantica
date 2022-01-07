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
defmodule Exsemantica.Database do
  @moduledoc """
  The ExSemantica Mnesia server, a `Consumer`.
  """
  require Logger
  use GenServer

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(args), do: GenServer.start_link(__MODULE__, args, name: __MODULE__)

  # ============================================================================
  # Callbacks
  # ============================================================================
  @impl true
  def init(tables: tables) do
    Logger.info("preparing distributed Mnesia")
    :ok = :net_kernel.monitor_nodes(true)

    :ok =
      case :mnesia.create_schema([node()]) do
        {:error, {_node0, {:already_exists, _node1}}} -> :ok
        :ok -> :ok
      end

    :mnesia.start()

    {:ok, %{tables: try_make_tables(tables), q: :queue.new()}}
  end

  @impl true
  def handle_info({:nodeup, node}, state = %{tables: tables}) do
    nodes = Node.list()
    Logger.info("node #{inspect(node)} joining #{inspect(nodes)}")

    {:ok, _nodes0} = :mnesia.change_config(:extra_db_nodes, nodes)

    ^tables = try_make_tables(tables)
    ^tables = try_make_table_copies(tables)

    {:noreply, [], state}
  end

  @impl true
  def handle_info({:nodedown, node}, state) do
    nodes = Node.list()

    Logger.info("node #{inspect(node)} left #{inspect(nodes)}")
    {:ok, _nodes0} = :mnesia.change_config(:extra_db_nodes, nodes)

    {:noreply, [], state}
  end

  @impl true
  def handle_events(events, _from, state) do
    pending =
      events
      |> Enum.map(fn oper ->
        case oper do
          %{operation: :get, source: source, table: table, info: info} ->
            fn ->
              Process.send(
                source,
                {Exsemantica.DatabasePacket,
                 %{
                   table: table,
                   info: info,
                   operation: :get,
                   content: :mnesia.read(table, info),
                   timestamp: DateTime.utc_now()
                 }},
                []
              )

              true
            end

          %{operation: :put, source: source, table: table, info: info} ->
            fn ->
              # for distribution's sake
              # ALSO: make unsticky if it's causing problems...

              Process.send(
                source,
                {Exsemantica.DatabasePacket,
                 %{
                   table: table,
                   info: info,
                   operation: :put,
                   content: :mnesia.write(table, info, :sticky_write),
                   timestamp: DateTime.utc_now()
                 }},
                []
              )

              true
            end
        end
      end)

    Logger.debug("#{length(pending)} transactions will execute now")

    :mnesia.transaction(fn ->
      # Pending transactions
      pending
      # Execute the anonymous functions...each success is truthy and rejected.
      |> Enum.reject(& &1.())
      # Check if the enum is empty. It should always be empty.
      |> Enum.empty?()
    end)

    {:noreply, [], state}
  end

  # ============================================================================
  # Private definitions
  # ============================================================================
  defp try_make_tables(tables) do
    cond do
      tables
      |> Enum.map(fn {name, attributes} ->
        {name, :mnesia.create_table(name, attributes: attributes)}
      end)
      |> Enum.all?(fn {name, chk} ->
        case chk do
          {:atomic, :ok} ->
            Logger.debug("enqueue make table #{inspect(name)} ok here")
            true

          {:aborted, {:already_exists, _name}} ->
            Logger.debug("enqueue make table #{inspect(name)} already ok before?")
            true

          error ->
            Logger.error("enqueue make table #{inspect(name)} failed: #{inspect(error)}")
            false
        end
      end) ->
        Logger.info("will make #{length(tables)} tables")

        :mnesia.change_table_copy_type(:schema, node(), :disc_copies)
        :ok = :mnesia.wait_for_tables(table_names(tables), 3000)

        Logger.info("tables done")

        tables
    end
  end

  defp try_make_table_copies(tables) do
    cond do
      tables
      |> Enum.map(fn {name, _attributes} ->
        {name, :mnesia.add_table_copy(name, node(), :disc_copies)}
      end)
      |> Enum.all?(fn {name, chk} ->
        case chk do
          {:atomic, :ok} ->
            Logger.debug("enqueue make table copy of #{inspect(name)} ok here")
            true

          {:aborted, {:already_exists, _table, _name}} ->
            Logger.debug("enqueue make table copy of #{inspect(name)} already ok before?")
            true

          error ->
            Logger.error("enqueue make table copy of #{inspect(name)} failed: #{inspect(error)}")
            false
        end
      end) ->
        Logger.info("copied #{length(tables)} tables")

        tables
    end
  end

  defp table_names(tables) do
    tables |> Enum.map(fn {name, _} -> name end)
  end
end
