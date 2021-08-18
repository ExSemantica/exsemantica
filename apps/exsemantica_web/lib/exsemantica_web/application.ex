defmodule ExSemantica.Web.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      ExSemantica.Web.Telemetry,
      # Start the Endpoint (http/https)
      ExSemantica.Web.Endpoint,
      # Start a worker by calling: ExSemantica.Web.Worker.start_link(arg)
      # {ExSemantica.Web.Worker, arg}
      {Phoenix.PubSub, name: ExSemantica.Web.PubSub}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ExSemantica.Web.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    ExSemantica.Web.Endpoint.config_change(changed, removed)
    :ok
  end
end
