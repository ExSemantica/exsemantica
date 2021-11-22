defmodule CloudcloneTest do
  use ExUnit.Case, async: true
  use Plug.Test
  doctest Cloudclone

  def handle_429(conn, _seconds) do
    conn = conn |> send_chunked(429)
    Task.async(fn -> conn |> chunk("429 Rate Limited\r\n") end)

  end

  def handle_403(conn) do
    conn = conn |> send_chunked(403)
    Task.async(fn -> conn |> chunk("403 Forbidden\r\n") end)
  end

  def handle(conn, ctx) do
    conn |> send_resp(200, "Hello #{ctx}!")
  end

  # ============================================================================
  test "handles sane requests" do
    {:ok, _cache} = start_supervised(Cloudclone.RateLimitCache)

    opts =
      Cloudclone.RateLimited.init(
        requested_limit: 2,
        interval: 1,
        on_limit: &__MODULE__.handle_429/2,
        on_forbidden: &__MODULE__.handle_403/1,
        on_success: &__MODULE__.handle/2
      )

    conn =
      conn(:get, "/")
      |> Cloudclone.RateLimited.call("world", opts)

    :ok = stop_supervised(Cloudclone.RateLimitCache)

    assert conn.state == :sent
    assert conn.status == 200
    assert conn.resp_body == "Hello world!"
  end

  # ============================================================================
  test "handles rate limiting" do
    {:ok, _cache} = start_supervised(Cloudclone.RateLimitCache)

    opts =
      Cloudclone.RateLimited.init(
        requested_limit: 2,
        interval: 1,
        on_limit: &__MODULE__.handle_429/2,
        on_forbidden: &__MODULE__.handle_403/1,
        on_success: &__MODULE__.handle/2
      )

    assert Enum.map(1..3, fn x ->
             conn(:get, "/")
             |> Cloudclone.RateLimited.call(x, opts)
           end)
           |> Enum.filter(fn m_conn ->
             m_conn.status == 429
           end)

    :ok = stop_supervised(Cloudclone.RateLimitCache)
  end

  # ============================================================================
  test "handles a theoretical service denial" do
    {:ok, _cache} = start_supervised(Cloudclone.RateLimitCache)

    opts =
      Cloudclone.RateLimited.init(
        requested_limit: 2,
        interval: 1,
        on_limit: &__MODULE__.handle_429/2,
        on_forbidden: &__MODULE__.handle_403/1,
        on_success: &__MODULE__.handle/2
      )

    assert Enum.map(1..25, fn x ->
             conn(:get, "/")
             |> Cloudclone.RateLimited.call(x, opts)
           end)
           |> Enum.filter(fn m_conn ->
             m_conn.status == 403
           end)

    :ok = stop_supervised(Cloudclone.RateLimitCache)
  end
  # ============================================================================
end
