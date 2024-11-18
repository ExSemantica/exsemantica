defmodule Exsemantica.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    Exsemantica.ApplicationInfo.refresh()

    children = [
      # Starts a worker by calling: Exsemantica.Worker.start_link(arg)
      # {Exsemantica.Worker, arg}
      {Bandit, plug: Exsemantica.API},
      {ThousandIsland, port: 6667, handler_module: Exsemantica.Chat},
      Exsemantica.Chat.ChannelSupervisor,
      Exsemantica.Chat.UserSupervisor,
      {Registry, keys: :unique, name: Exsemantica.Chat.ChannelRegistry},
      {Registry, keys: :unique, name: Exsemantica.Chat.UserRegistry},
      {Registry, keys: :unique, name: Exsemantica.PubSub.ServerRegistry},
      Exsemantica.Repo,
      Exsemantica.Cache,
      Exsemantica.PubSub
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Exsemantica.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
