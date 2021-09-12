defmodule ExsemanticaApi.RateLimited do
  @moduledoc """
  Creates an `Agent` that is rate limited.

  Call "fire" to fire the rate limiter. This is also globally rate limited on the
  endpoint scope to suppress the effects of a DDoS attack.
  """
  defmacro __using__(kw_opts) do
    quote do
      @behaviour ExsemanticaApi.RateLimited

      use Agent

      @local_max_tokens unquote(Keyword.get(kw_opts, :local_tmax, 2))
      @max_tokens unquote(Keyword.get(kw_opts, :tmax, 10))
      @local_stale_after unquote(Keyword.get(kw_opts, :local_tstale, 1))
      @global_stale_after unquote(Keyword.get(kw_opts, :tstale, 1))

      defmodule __MODULE__.State do
        @enforce_keys [:global_tokens]
        defstruct global_tokens: nil, token_pool: %{}, stale_after: 0

        @type t :: %__MODULE__{
                global_tokens: non_neg_integer,
                token_pool: map,
                stale_after: non_neg_integer
              }
      end

      def start_link(opts) do
        Agent.start_link(
          fn ->
            %__MODULE__.State{global_tokens: @max_tokens}
          end,
          opts
        )
      end

      def fire(agent, proc, idx) do
        Agent.get_and_update(agent, fn state_old ->
          unix = DateTime.utc_now() |> DateTime.to_unix()

          case {if(state_old.stale_after > unix, do: state_old.global_tokens, else: @max_tokens),
                get_in(state_old.token_pool, [idx])} do
            {gtok, nil} when gtok > 0 ->
              code =
                handle_use(
                  agent,
                  %__MODULE__.State{
                    state_old
                    | global_tokens: gtok - 1,
                      stale_after: unix + @global_stale_after,
                      token_pool:
                        state_old.token_pool
                        |> put_in([idx], {@local_max_tokens, unix + @local_stale_after})
                  },
                  idx
                )

              case code do
                {:noreply, state} ->
                  {state_old, state}

                {:reply, state, response} ->
                  send(proc, response)
                  {state_old, state}
              end

            {gtok, {ltok, last}} when gtok > 0 and ltok > 0 ->
              code =
                handle_use(
                  agent,
                  %__MODULE__.State{
                    state_old
                    | global_tokens: gtok - 1,
                      stale_after: unix + @global_stale_after,
                      token_pool:
                        state_old.token_pool
                        |> update_in([idx], fn _ ->
                          {
                            if(unix < last, do: ltok - 1, else: @local_max_tokens),
                            unix + @local_stale_after
                          }
                        end)
                  },
                  idx
                )

              case code do
                {:noreply, state} ->
                  {state_old, state}

                {:reply, state, response} ->
                  send(proc, response)
                  {state_old, state}
              end

            {gtok, {0, last}} when gtok > 0 ->
              code =
                handle_local_throttle(
                  agent,
                  %__MODULE__.State{
                    state_old
                    | global_tokens: gtok - 1,
                      stale_after: unix + @global_stale_after,
                      token_pool:
                        state_old.token_pool
                        |> update_in([idx], fn _ ->
                          {
                            if(unix < last, do: 0, else: @local_max_tokens),
                            unix + @local_stale_after
                          }
                        end)
                  },
                  idx
                )

              case code do
                {:noreply, state} ->
                  {state_old, state}

                {:reply, state, response} ->
                  send(proc, response)
                  {state_old, state}
              end

            {_, _} ->
              code =
                handle_global_throttle(
                  agent,
                  %__MODULE__.State{
                    state_old
                    | stale_after: unix + @global_stale_after
                  },
                  idx
                )

              case code do
                {:noreply, state} ->
                  {state_old, state}

                {:reply, state, response} ->
                  send(proc, response)
                  {state_old, state}
              end
          end
        end)
      end
    end
  end

  @callback handle_use(pid, __MODULE__.State.t(), any) ::
              {:reply, __MODULE__.State.t(), any} | {:noreply, __MODULE__.State.t()}
  @callback handle_local_throttle(pid, __MODULE__.State.t(), any) ::
              {:reply, __MODULE__.State.t(), any} | {:noreply, __MODULE__.State.t()}
  @callback handle_global_throttle(pid, __MODULE__.State.t(), any) ::
              {:reply, __MODULE__.State.t(), any} | {:noreply, __MODULE__.State.t()}
end
