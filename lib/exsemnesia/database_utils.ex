defmodule Exsemnesia.Utils do
  @moduledoc """
  Utilities for the Mnesia database to make things easier.
  """
  require Exsemnesia.Handle128

  def increment(type) do
    cnt = :mnesia.dirty_update_counter(:counters, type, 1)
    <<cnt::128>>
  end

  def increment_popularity(table, idx) do
    %{
      operation: :rank,
      table: table,
      info: %{idx: idx, inc: 1}
    }
  end

  # ============================================================================
  # Put items
  # ============================================================================
  def put_user(raw_handle) do
    if Exsemnesia.Handle128.is_valid(raw_handle) do
      handle = Exsemnesia.Handle128.serialize(raw_handle)

      if unique(handle) do
        %{
          operation: :put,
          table: :users,
          info: {:users, increment(:id_count), DateTime.utc_now(), handle}
        }
      else
        {:error, :eusers}
      end
    else
      {:error, :einval}
    end
  end

  def put_post(raw_handle, title, content, user) do
    if Exsemnesia.Handle128.is_valid(raw_handle) do
      handle = Exsemnesia.Handle128.serialize(raw_handle)

      if unique(handle) do
        %{
          operation: :put,
          table: :posts,
          info: {:posts, increment(:id_count), DateTime.utc_now(), handle, title, content, user}
        }
      else
        {:error, :eusers}
      end
    else
      {:error, :einval}
    end
  end

  def put_interest(raw_handle, title, content, related_to) do
    if Exsemnesia.Handle128.is_valid(raw_handle) do
      handle = Exsemnesia.Handle128.serialize(raw_handle)

      if unique(handle) do
        %{
          operation: :put,
          table: :interests,
          info: {:interests, increment(:id_count), DateTime.utc_now(), title, content, related_to}
        }
      else
        {:error, :eusers}
      end
    else
      {:error, :einval}
    end
  end

  # ============================================================================
  # Get items
  # ============================================================================
  def get(table, idx) do
    %{
      operation: :get,
      table: table,
      info: idx
    }
  end

  def count(table, key, value) do
    %{
      operation: :count,
      table: table,
      info: %{key: key, value: value}
    }
  end

  def trending(count) do
    %{
      operation: :tail,
      table: :ctrending,
      info: count
    }
  end

  defp unique(handle) do
    {:atomic, uniqs} =
      [
        Exsemnesia.Utils.count(:users, :handle, handle),
        Exsemnesia.Utils.count(:posts, :handle, handle),
        Exsemnesia.Utils.count(:interests, :handle, handle)
      ]
      |> Exsemnesia.Database.transaction()

    uniqs
    |> Enum.all?(fn %{operation: :count, table: _table, info: _info, response: response} ->
      response == 0
    end)
  end
end
