defmodule Exsemantica.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    :persistent_term.put(
      Exsemantica.Version,
      case Application.get_env(:exsemantica, :commit_sha_result) do
        {sha, 0} ->
          sha |> String.replace_trailing("\n", "")

          "#{Application.spec(:exsemantica, :vsn)}-#{sha}"

        _ ->
          Application.spec(:exsemantica, :vsn)
      end
    )

    children = [
      # Start the Telemetry supervisor
      ExsemanticaWeb.Telemetry,
      # Start the Ecto repository
      Exsemantica.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Exsemantica.PubSub},
      # Start Finch
      {Finch, name: Exsemantica.Finch},
      # Start the Endpoint (http/https)
      ExsemanticaWeb.Endpoint
      # Start a worker by calling: Exsemantica.Worker.start_link(arg)
      # {Exsemantica.Worker, arg}
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
