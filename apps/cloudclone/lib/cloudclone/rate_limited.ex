defmodule Cloudclone.RateLimited do
  @moduledoc """
  Global rate limiting `Plug`. Use this as a basis for implementing a rate
  limited HTTP endpoint.
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
          any,
          [
            {:interval, non_neg_integer}
            | {:on_forbidden, any}
            | {:on_limit, any}
            | {:on_success, any}
            | {:requested_limit, non_neg_integer},
            ...
          ]
        ) :: Plug.Conn.t()
  def call(conn, context,
        requested_limit: requested_limit,
        interval: interval,
        on_limit: limit_fun,
        on_forbidden: forbidden_fun,
        on_success: success_fun
      ) do
    encoded_ip =
      case conn.remote_ip do
        # IPv4
        {i0, i1, i2, i3} ->
          <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 255, 255, i0, i1, i2, i3>>

        # IPv6
        {i0, i1, i2, i3, i4, i5, i6, i7} ->
          <<i0::big-16, i1::big-16, i2::big-16, i3::big-16, i4::big-16, i5::big-16, i6::big-16,
            i7::big-16>>
      end

    my_bucket = Base.url_encode64(:crypto.hash(:sha256, encoded_ip))

    case Cloudclone.RateLimitCache.fire(my_bucket, requested_limit, interval) do
      # The user has loaded the page too often.
      {:error, {:rate_limited, seconds}} ->
        {:ok, conn} = conn |> limit_fun.(seconds) |> Task.await()
        conn

      # The user has, additionally, not complied with the rate limiting headers.
      # This is where the connection is forbidden.
      {:error, :forbidden} ->
        {:ok, conn} = conn |> forbidden_fun.() |> Task.await()
        conn

      {:ok, resp} ->
        conn
        |> put_resp_header("x-ratelimit-bucket", my_bucket)
        |> put_resp_header("x-ratelimit-limit", to_string(resp.limit))
        |> put_resp_header("x-ratelimit-remaining", to_string(resp.remaining))
        |> put_resp_header("x-ratelimit-reset", to_string(resp.reset))
        |> success_fun.(context)
    end
  end
end
