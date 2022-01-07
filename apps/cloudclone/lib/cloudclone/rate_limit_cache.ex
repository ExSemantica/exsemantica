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
defmodule Cloudclone.RateLimitCache do
  @moduledoc """
  Caches rate limit states for different buckets.

  You can use this to implement your own rate limited endpoint, Plug or not.
  """
  require Logger
  use GenServer
  @brutal_limit 7200

  # ============================================================================
  # Behavioral Callbacks
  # ============================================================================
  @impl true
  def init(_opts) do
    {:ok, :ets.new(:rate_limits, [:set, :private])}
  end

  @impl true
  def handle_call({:request, idx, limit, interval}, _from, state) do
    unix = DateTime.utc_now() |> DateTime.to_unix()

    case :ets.lookup(state, idx) do
      [] ->
        pack = %{limit: limit, remaining: limit - 1, reset: unix + interval}
        :ets.insert(state, {idx, pack, 1})
        {:reply, {:ok, pack}, state}

      [{_idx, old, multi}] ->
        %{limit: _limit, remaining: remaining, reset: reset} = old

        cond do
          # expired
          reset < unix ->
            :ets.insert(
              state,
              {idx, new = %{old | remaining: limit - 1, reset: unix + interval}, 1}
            )

            {:reply, {:ok, new}, state}

          # normal operational mode
          remaining > 0 ->
            :ets.insert(state, {idx, new = %{old | remaining: remaining - 1}, multi})
            {:reply, {:ok, new}, state}

          # rate limits
          multi < @brutal_limit ->
            new_multi = multi * 2
            Logger.info("Rate limit hit, multiplier for '#{inspect(idx)}' is now #{new_multi}.")
            :ets.insert(state, {idx, %{old | reset: unix + interval * multi}, new_multi})
            {:reply, {:error, {:rate_limited, new_multi * interval}}, state}

          true ->
            Logger.notice("Rate limit hit, '#{inspect(idx)}' is forbidden from further usage.")
            {:reply, {:error, :forbidden}, state}
        end
    end
  end

  # ============================================================================
  # Calls and Casts
  # ============================================================================
  @doc """
  Starts the rate limiter cache.
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec fire(any, non_neg_integer, non_neg_integer) ::
          {:ok, any} | {:error, {:rate_limited, non_neg_integer} | :forbidden}
  @doc """
  Fires the rate limiter cache with a unique identifier "idx".
  """
  def fire(idx, requested_limit \\ 2, interval \\ 1) do
    GenServer.call(__MODULE__, {:request, idx, requested_limit, interval})
  end
end
