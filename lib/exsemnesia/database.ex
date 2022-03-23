defmodule Exsemnesia.Database do
  @moduledoc """
  The ExSemantica Mnesia server.
  """
  require Logger
  use GenServer

  @noboost_htimestamp_secs 5
  @epoch ~U[1970-01-01 00:00:00Z]

  @doc """
  Starts the Mnesia server for this application instance.
  TODO: Document the Mnesia server nodes' autojoining mechanism, and also give
  an option for making the nodes not autojoin.
  """
  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(args), do: GenServer.start_link(__MODULE__, args, name: __MODULE__)

  @doc """
  Makes the Mnesia server process a list of transactions, reading and/or writing.
  """
  @spec transaction(any) :: any
  def transaction(transactions) do
    GenServer.call(__MODULE__, {:transaction, transactions})
  end

  # ============================================================================
  # Callbacks
  # ============================================================================
  @impl true
  def init(
        tables: tables,
        caches: caches,
        tcopts: %{
          extra_indexes: indices,
          ordered_caches: order_these,
          seed_trends: seeds,
          seed_seeder: seeder
        }
      ) do
    Logger.info("preparing distributed Mnesia")
    :ok = :net_kernel.monitor_nodes(true)

    :ok =
      case :mnesia.create_schema([node()]) do
        {:error, {_node0, {:already_exists, _node1}}} -> :ok
        :ok -> :ok
      end

    :mnesia.start()

    resp = %{
      tables: tables |> Map.to_list() |> try_make_tables(),
      caches: caches |> Map.to_list() |> try_make_caches(order_these)
    }

    indices |> assemble_indices

    for seed <- seeds do
      Logger.debug("populating initial ctrending entries for #{inspect(seed)}")

      :mnesia.transaction(fn ->
        :mnesia.foldl(
          fn entry, _acc ->
            seeder.(entry)
          end,
          0,
          seed
        )
      end)
    end

    {:ok, resp}
  end

  @impl true
  def handle_info(
        {:nodeup, node},
        state = %{
          tables: tables,
          caches: caches,
          tcopts: %{extra_indexes: indices, ordered_caches: order_these}
        }
      ) do
    nodes = Node.list()
    Logger.info("node #{inspect(node)} joining #{inspect(nodes)}")

    {:ok, _nodes0} = :mnesia.change_config(:extra_db_nodes, nodes)

    ^tables = try_make_tables(tables)
    ^tables = try_make_table_copies(tables)

    ^caches = try_make_caches(caches, order_these)
    ^caches = try_make_cache_copies(caches)

    indices |> assemble_indices

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
  def handle_call({:transaction, events}, _from, state) do
    pending =
      events
      |> Enum.map(fn oper ->
        case oper do
          # Item Count
          %{operation: :count, table: table, info: info = %{key: key, value: value}} ->
            fn ->
              %{
                table: table,
                info: info,
                operation: :count,
                response: length(:mnesia.index_read(table, value, key))
              }
            end

          # Item Get
          %{operation: :get, table: table, info: info} ->
            fn ->
              %{
                table: table,
                info: info,
                operation: :get,
                response: :mnesia.read(table, info)
              }
            end

          # Item Index
          %{operation: :index, table: table, info: info = %{key: key, value: value}} ->
            fn ->
              %{
                table: table,
                info: info,
                operation: :get,
                response: :mnesia.index_read(table, value, key)
              }
            end

          # Item Put
          %{operation: :put, table: table, info: info, idh: idh} when not is_nil(idh) ->
            fn ->
              {id, handle} = idh

              # Writes the ctrending entry strongly.
              :mnesia.write(
                :ctrending,
                {:ctrending, {0, id}, id, table,
                 DateTime.utc_now() |> DateTime.add(@noboost_htimestamp_secs), handle},
                :sticky_write
              )

              # Writes the lowercases entry strongly.
              :mnesia.write(
                :lowercases,
                {:lowercases, handle, String.downcase(handle, :ascii)},
                :sticky_write
              )

              # for distribution's sake
              # ALSO: make unsticky if it's causing problems...
              %{
                table: table,
                info: info,
                operation: :put,
                response: :mnesia.write(table, info, :sticky_write)
              }
            end

          %{operation: :put, table: table, info: info} ->
            fn ->
              %{
                table: table,
                info: info,
                operation: :put,
                response: :mnesia.write(table, info, :sticky_write)
              }
            end

          # Gets the tail of an ordered set
          %{operation: :tail, table: table, info: info} ->
            fn ->
              {accum, _cnt} =
                :mnesia.foldr(
                  fn record, {acc, cnt} ->
                    case record do
                      [] -> {acc, 0}
                      _ when cnt > 0 -> {[record | acc], cnt - 1}
                      _ -> {acc, 0}
                    end
                  end,
                  {[], info},
                  table
                )

              %{
                table: table,
                info: info,
                operation: :tail,
                response: accum
              }
            end

          # Gets the head of an ordered set
          %{operation: :head, table: table, info: info} ->
            fn ->
              {accum, _cnt} =
                :mnesia.foldl(
                  fn record, {acc, cnt} ->
                    case record do
                      [] -> {acc, 0}
                      _ when cnt > 0 -> {[record | acc], cnt - 1}
                      _ -> {acc, 0}
                    end
                  end,
                  {[], info},
                  table
                )

              %{
                table: table,
                info: info,
                operation: :head,
                response: accum
              }
            end

          # Dump all entries of a table. This is an intensive operation.
          %{operation: :dump, table: table} ->
            fn ->
              %{
                table: table,
                operation: :dump,
                response: :mnesia.foldr(fn record, acc -> [record | acc] end, [], table)
              }
            end

          # Like Enum.map on the entire data dump
          %{operation: :map, table: table, info: fun} ->
            fn ->
              %{
                table: table,
                operation: :dump,
                response: :mnesia.foldr(fn record, acc -> [fun.(record) | acc] end, [], table)
              }
            end

          # Handles modifying the ranking of a certain ctrending entry
          %{operation: :rank, table: table, info: info} ->
            fn ->
              pre = :mnesia.read(table, idx = info.idx)

              pre_handle =
                case table do
                  :users ->
                    {_node, _timestamp, handle, _privmask} = pre
                    handle

                  :posts ->
                    {_node, _timestamp, handle, _title, _content, _posted_by} = pre
                    handle

                  :interests ->
                    {_node, _timestamp, handle, _title, _content, _related_to} = pre
                    handle
                end

              this =
                {:ctrending, {pop, ^idx}, ^idx, ^table, htimestamp, handle} =
                case :mnesia.index_read(:ctrending, info.idx, :node) do
                  [] ->
                    {:ctrending, {0, idx}, idx, table, @epoch, pre_handle}

                  [exist] ->
                    exist
                end

              now = DateTime.utc_now()

              :ok =
                case DateTime.compare(now, htimestamp) do
                  :gt ->
                    :mnesia.delete_object(:ctrending, this, :sticky_write)

                    :mnesia.write(
                      :ctrending,
                      {:ctrending, {pop + info.inc, idx}, idx, table,
                       DateTime.add(now, @noboost_htimestamp_secs), handle},
                      :sticky_write
                    )

                  _ ->
                    :ok
                end

              %{
                table: table,
                info: info,
                operation: :rank,
                response: %{
                  node: idx,
                  type: table,
                  handle: handle
                }
              }
            end
        end
      end)

    Logger.debug("#{length(pending)} transactions will execute now")

    {:reply,
     :mnesia.transaction(fn ->
       # Pending transactions
       pending
       # Execute their anonymous functions...
       |> Enum.map(& &1.())
     end), state}
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
        table_names(tables) |> Enum.map(&:mnesia.change_table_copy_type(&1, node(), :disc_copies))

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

  defp try_make_caches(caches, ordered_caches) do
    cond do
      caches
      |> Enum.map(fn {name, attributes} ->
        if ordered_caches |> Enum.member?(name) do
          Logger.debug("enqueue make cache #{inspect(name)} is ORDERED")
          {name, :mnesia.create_table(name, attributes: attributes, type: :ordered_set)}
        else
          Logger.debug("enqueue make cache #{inspect(name)} is UN-ORDERED")
          {name, :mnesia.create_table(name, attributes: attributes)}
        end
      end)
      |> Enum.all?(fn {name, chk} ->
        case chk do
          {:atomic, :ok} ->
            Logger.debug("enqueue make cache #{inspect(name)} ok here")
            true

          {:aborted, {:already_exists, _table}} ->
            Logger.debug("enqueue make cache #{inspect(name)} already ok in schema?")
            true

          error ->
            Logger.error("enqueue make cache #{inspect(name)} failed: #{inspect(error)}")
            false
        end
      end) ->
        Logger.info("will make #{length(caches)} caches")

        :ok = :mnesia.wait_for_tables(table_names(caches), 3000)
        table_names(caches) |> Enum.map(&:mnesia.change_table_copy_type(&1, node(), :ram_copies))

        Logger.info("caches done")

        caches
    end
  end

  defp try_make_cache_copies(tables) do
    cond do
      tables
      |> Enum.map(fn {name, _attributes} ->
        {name, :mnesia.add_table_copy(name, node(), :ram_copies)}
      end)
      |> Enum.all?(fn {name, chk} ->
        case chk do
          {:atomic, :ok} ->
            Logger.debug("enqueue make cache copy of #{inspect(name)} ok here")
            true

          error ->
            Logger.error("enqueue make cache copy of #{inspect(name)} failed: #{inspect(error)}")
            false
        end
      end) ->
        Logger.info("copied #{length(tables)} caches")

        tables
    end
  end

  defp table_names(tables) do
    tables |> Enum.map(fn {name, _} -> name end)
  end

  defp assemble_indices(indices) do
    indices
    |> Enum.map(fn {k, index_list} ->
      index_list
      |> Enum.map(fn index ->
        case :mnesia.add_table_index(k, index) do
          {:atomic, :ok} ->
            Logger.debug("added secondary index #{inspect(index)} to table/cache #{inspect(k)}")

          {:aborted, {:already_exists, _table, _index}} ->
            Logger.debug(
              "secondary index #{inspect(index)} to table/cache #{inspect(k)} is already present"
            )
        end
      end)
    end)
  end
end
