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
defmodule Exsemtheme.Router do
  @moduledoc """
  Frontend request router
  """
  require Logger
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  # ============================================================================
  # Fetch assets
  # ============================================================================
  # Favicon
  get "/favicon.ico" do
    conn
    |> send_resp(
      200,
      File.read!(Path.join([Application.fetch_env!(:exsemtheme, :out), "favicon.ico"]))
    )
  end

  # Output assets
  get "/res/:resource" do
    conn
    |> send_resp(
      200,
      File.read!(Path.join([Application.fetch_env!(:exsemtheme, :out), resource]))
    )
  end

  get "/" do
    Logger.info("200 fetch homepage", conn: inspect(conn))

    conn
    |> send_resp(
      404,
      Exsemtheme.ThemingAgent.apply(:frontpage,
        intent: "Home",
        main: ~s"""
        <p>Work-in-progress webpage. The following placeholder text is for testing the CSS flex box system.</p>
        <p>Kitty ipsum dolor sit amet, shed everywhere shed everywhere stretching attack your ankles chase the red dot, hairball run catnip eat the grass sniff.</p>
        """,
        aside: get_aside()
      )
    )
  end

  match _ do
    Logger.info("404 fetching unhandled content", conn: inspect(conn))

    conn
    |> send_resp(
      404,
      Exsemtheme.ThemingAgent.apply(:frontpage,
        intent: "404 Not Found",
        main: "The requested page could not be found.\r\n",
        aside: get_aside()
      )
    )
  end

  # ============================================================================
  # Handle fetching "aside" content
  # ============================================================================
  defp get_aside do
    "This isn't implemented yet. It may be soon.\r\n"
  end
end
