defmodule ExsemanticaPhx.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      ExsemanticaPhx.Repo,
      # Start the Telemetry supervisor
      ExsemanticaPhxWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: ExsemanticaPhx.PubSub},
      # Start the Endpoint (http/https)
      ExsemanticaPhxWeb.Endpoint,
      # Start the Graph Database
      {LdGraph2.Agent, [kvstore_name: "exsemantica", opts: [name: ExsemanticaPhx.GraphStore]]}
      # Start a worker by calling: ExsemanticaPhx.Worker.start_link(arg)
      # {ExsemanticaPhx.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ExsemanticaPhx.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    ExsemanticaPhxWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
