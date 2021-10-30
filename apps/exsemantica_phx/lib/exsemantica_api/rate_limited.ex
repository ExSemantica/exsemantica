defmodule ExsemanticaApi.RateLimited do
  @moduledoc """
  Global rate limiting `Plug`.
  """
  import Plug.Conn

  @spec init(any) :: any
  def init(opts) do
    opts
  end

  @spec call(
          atom
          | %{
              :remote_ip =>
                {integer, integer, integer, integer}
                | {integer, integer, integer, integer, integer, integer, integer, integer},
              optional(any) => any
            },
          [
            {:interval, non_neg_integer}
            | {:on_forbidden, any}
            | {:on_limit, any}
            | {:requested_limit, non_neg_integer},
            ...
          ]
        ) :: Plug.Conn.t()
  def call(conn,
        requested_limit: requested_limit,
        interval: interval,
        on_limit: limit_fun,
        on_forbidden: forbidden_fun
      ) do
    encoded_ip =
      case conn.remote_ip do
        # IPv4
        {i0, i1, i2, i3} -> <<i0, i1, i2, i3>>
        # IPv6
        {i0, i1, i2, i3, i4, i5, i6, i7} -> <<i0, i1, i2, i3, i4, i5, i6, i7>>
      end

    my_bucket = Base.url_encode64(:crypto.hash(:sha256, encoded_ip))

    case ExsemanticaApi.RateLimitCache.fire(my_bucket, requested_limit, interval) do
      # The user has loaded the page too often.
      {:error, {:rate_limited, seconds}} ->
        {:ok, conn} = conn |> limit_fun.(seconds) |> Task.await()
        conn |> halt

      # The user has, additionally, not complied with the rate limiting headers.
      # This is where the connection is forbidden.
      {:error, :forbidden} ->
        {:ok, conn} = conn |> forbidden_fun.() |> Task.await()
        conn |> halt

      {:ok, resp} ->
        conn
        |> put_resp_header("x-ratelimit-bucket", my_bucket)
        |> put_resp_header("x-ratelimit-limit", to_string(resp.limit))
        |> put_resp_header("x-ratelimit-remaining", to_string(resp.remaining))
        |> put_resp_header("x-ratelimit-reset", to_string(resp.reset))
    end
  end
end
