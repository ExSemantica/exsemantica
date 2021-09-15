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

      defmodule __MODULE__.Context do
        @enforce_keys [:global_tokens]
        defstruct global_tokens: nil, token_pool: %{}, stale_after: 0

        @type t :: %__MODULE__{
                global_tokens: integer,
                token_pool: map,
                stale_after: non_neg_integer
              }
      end

      def start_link(opts) do
        Agent.start_link(
          fn ->
            %__MODULE__.Context{global_tokens: @max_tokens}
          end,
          opts
        )
      end

      def fire(agent, idx, extra) do
        proc = self()

        Agent.get_and_update(agent, fn context_old ->
          unix = DateTime.utc_now() |> DateTime.to_unix()

          %{global: global_delta, extra: extra} =
            handle_pressure(agent, idx, extra)

          case {if(context_old.stale_after > unix,
                  do: context_old.global_tokens,
                  else: @max_tokens
                ), get_in(context_old.token_pool, [idx])} do
            {gtok, nil} when gtok > 0 ->
              code =
                handle_use(
                  agent,
                  %__MODULE__.Context{
                    context_old
                    | global_tokens: gtok - global_delta,
                      stale_after: unix + @global_stale_after,
                      token_pool:
                        context_old.token_pool
                        |> put_in([idx], {@local_max_tokens, unix + @local_stale_after})
                  },
                  idx,
                  extra
                )

              case code do
                {:noreply, context} ->
                  {context_old, context}

                {:reply, context, response} ->
                  send(proc, {:rate_limit_used, response, %{
                    :limit => @local_max_tokens,
                    :remaining => @local_max_tokens,
                    :reset => unix + @local_stale_after,
                  }})
                  {context_old, context}
              end

            {gtok, {ltok, last}} when gtok > 0 and ltok > 0 ->
              local_off = if(unix < last, do: ltok - 1, else: @local_max_tokens)
              code =
                handle_use(
                  agent,
                  %__MODULE__.Context{
                    context_old
                    | global_tokens: gtok - global_delta,
                      stale_after: unix + @global_stale_after,
                      token_pool:
                        context_old.token_pool
                        |> update_in([idx], fn _ ->
                          {
                            local_off,
                            unix + @local_stale_after
                          }
                        end)
                  },
                  idx,
                  extra
                )

              case code do
                {:noreply, context} ->
                  {context_old, context}

                {:reply, context, response} ->
                  send(proc, {:rate_limit_used, response, %{
                    :limit => @local_max_tokens,
                    :remaining => local_off,
                    :reset => unix + @local_stale_after,
                  }})
                  {context_old, context}
              end

            {gtok, {_, last}} when gtok > 0 ->
              local_off = if(unix < last, do: 0, else: @local_max_tokens)
              code =
                handle_local_throttle(
                  agent,
                  %__MODULE__.Context{
                    context_old
                    | global_tokens: gtok - global_delta,
                      stale_after: unix + @global_stale_after,
                      token_pool:
                        context_old.token_pool
                        |> update_in([idx], fn _ ->
                          {
                            local_off,
                            unix + @local_stale_after
                          }
                        end)
                  },
                  idx,
                  extra
                )

              case code do
                {:noreply, context} ->
                  {context_old, context}

                {:reply, context, response} ->
                  send(proc, {:rate_limit_used, response, %{
                    :limit => @local_max_tokens,
                    :remaining => local_off,
                    :reset => unix + @local_stale_after,
                  }})
                  {context_old, context}
              end

            {_, _} ->
              code =
                handle_global_throttle(
                  agent,
                  %__MODULE__.Context{
                    context_old
                    | global_tokens: 0,
                      stale_after: unix + @global_stale_after
                  },
                  idx,
                  extra
                )

              case code do
                {:noreply, context} ->
                  {context_old, context}

                {:reply, context, response} ->
                  send(proc, {:rate_global_stall, response})
                  {context_old, context}
              end
          end
        end)
      end
    end
  end

  @callback handle_pressure(pid, __MODULE__.Context.t(), any) :: non_neg_integer
  @callback handle_use(pid, __MODULE__.Context.t(), any, any) ::
              {:reply, __MODULE__.Context.t(), any} | {:noreply, __MODULE__.Context.t()}
  @callback handle_local_throttle(pid, __MODULE__.Context.t(), any, any) ::
              {:reply, __MODULE__.Context.t(), any} | {:noreply, __MODULE__.Context.t()}
  @callback handle_global_throttle(pid, __MODULE__.Context.t(), any, any) ::
              {:reply, __MODULE__.Context.t(), any} | {:noreply, __MODULE__.Context.t()}
end
