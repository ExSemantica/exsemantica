defmodule Exsemantica.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    # Start Mnesia
    :mnesia.create_schema([Node.self()])
    :mnesia.start()

    # Put version into an Erlang/OTP persistent term
    :persistent_term.put(
      Exsemantica.Version,
      case Application.get_env(:exsemantica, :commit_sha_result) do
        {sha, 0} ->
          "v#{Application.spec(:exsemantica, :vsn)}-git-#{sha |> String.replace_trailing("\n", "")}"

        _ ->
          "v#{Application.spec(:exsemantica, :vsn)}"
      end
    )
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

    Logger.info("Exsemantica #{:persistent_term.get(Exsemantica.Version)} starting")

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
