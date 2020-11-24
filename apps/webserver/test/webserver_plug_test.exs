defmodule Webserver.PlugTest do
  use ExUnit.Case, async: true
  use Plug.Test
  doctest Webserver.Plug

  test "proper routes pass with 200" do
    conn = Webserver.Plug.call(conn(:get, "/"), nil)
    assert conn.status == 200
  end

  test "improper routes fail with 404" do
    conn = Webserver.Plug.call(conn(:get, "/foo"), nil)
    assert conn.status == 404
  end
end
