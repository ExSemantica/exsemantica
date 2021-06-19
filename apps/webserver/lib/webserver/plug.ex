# Copyright 2020-2021 Roland Metivier
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
defmodule Webserver.Plug do
  use Plug.Router

  plug(Plug.Logger)
  plug(:match)
  plug(:dispatch)

  get "/" do
    {:ok, json} = Jason.encode(%{"object" => []})
    conn |> put_resp_content_type("application/json") |> send_resp(200, json)
  end

  match _ do
    {:ok, json} = Jason.encode(%{"object" => nil})
    conn |> put_resp_content_type("application/json") |> send_resp(404, json)
  end
end
