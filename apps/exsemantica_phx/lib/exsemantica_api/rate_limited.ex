defmodule ExsemanticaApi.RateLimited do
  @moduledoc """
  Global rate limiting `Plug`.
  """
  import Plug.Conn

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    encoded_ip =
      case conn.remote_ip do
        # IPv4
        {i0, i1, i2, i3} -> <<i0, i1, i2, i3>>
        # IPv6
        {i0, i1, i2, i3, i4, i5, i6, i7} -> <<i0, i1, i2, i3, i4, i5, i6, i7>>
      end

    my_bucket = Base.url_encode64(:crypto.hash(:sha256, encoded_ip))

    case ExsemanticaApi.RateLimitCache.fire(my_bucket) do
      {:error, {:rate_limited, secs}} ->
        conn
        |> send_resp(429, "You are being rate limited, try again in #{secs} seconds")
        |> halt

      {:error, :forbidden} ->
        conn
        |> send_resp(403, "Forbidden")
        |> halt

      {:ok, resp} ->
        conn
        |> put_resp_header("x-ratelimit-bucket", my_bucket)
        |> put_resp_header("x-ratelimit-limit", to_string(resp.limit))
        |> put_resp_header("x-ratelimit-remaining", to_string(resp.remaining))
        |> put_resp_header("x-ratelimit-reset", to_string(resp.reset))
    end
  end
end
