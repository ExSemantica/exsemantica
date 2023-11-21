defmodule Exsemantica.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ExsemanticaWeb.Telemetry,
      Exsemantica.Repo,
      {DNSCluster, query: Application.get_env(:exsemantica, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Exsemantica.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Exsemantica.Finch},
      # Start a worker by calling: Exsemantica.Worker.start_link(arg)
      # {Exsemantica.Worker, arg},
      # Start to serve requests, typically the last entry
      ExsemanticaWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Exsemantica.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ExsemanticaWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
