defmodule Exsemtheme.Router do
  @moduledoc """
  Frontend request router
  """
  require Logger
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  # ============================================================================
  # Nothing of note
  # ============================================================================
  get "/res/:resource" do
    conn
    |> send_resp(
      200,
      File.read!(Path.join([Application.fetch_env!(:exsemtheme, :out), resource]))
    )
  end

  match _ do
    Logger.info("404 fetching unhandled content", conn: inspect(conn))

    conn
    |> send_resp(
      404,
      Exsemtheme.ThemingAgent.apply(:frontpage, main: "Oh no, 404, WIP site no?\r\n", aside: "Free cocoa!\r\n")
    )
  end
end
