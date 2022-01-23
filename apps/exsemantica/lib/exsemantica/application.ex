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
defmodule Exsemantica.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  require Logger
  use Application

  @impl true
  def start(_type, _args) do
    children =
      cond do
        Application.fetch_env!(:exsemantica, :test_mode) ->
          Logger.debug("In test, will not start usual ExSemantica services")
          []

        true ->
          [
            # Starts a worker by calling: Exsemantica.Worker.start_link(arg)
            # {Exsemantica.Worker, arg}
            {Exsemantica.Database,
             tables: [
               {:users, ~w(node handle)a},
               {:posts, ~w(node title content posted_by)a},
               {:interests, ~w(node title content related_to)a},
               {:counters, ~w(type count)a}
             ]},
            {Plug.Cowboy,
             scheme: :http,
             plug: Exsemantica.PlugApi,
             port: Application.fetch_env!(:exsemantica, :port)}
          ]
      end

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Exsemantica.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
