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
defmodule Exsemtheme.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  require Logger
  use Application

  @impl true
  def start(_type, _args) do
    Logger.notice("Running ESBuild...")
    Esbuild.run(:default, [])
    Logger.notice("Running TailwindCSS...")
    Tailwind.run(:default, [])

    children = [
      # Starts a worker by calling: Exsemtheme.Worker.start_link(arg)
      # {Exsemtheme.Worker, arg}

      {Plug.Cowboy,
       scheme: :http, plug: Exsemtheme.Router, port: Application.fetch_env!(:exsemtheme, :port)},
      {Exsemtheme.ThemingAgent, theme: Application.fetch_env!(:exsemtheme, :theme)}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Exsemtheme.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
