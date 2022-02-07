defmodule Exsemantica.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      ExsemanticaWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Exsemantica.PubSub},
      # Start the Endpoints (http/https)
      ExsemanticaWeb.Endpoint,
      {Absinthe.Subscription, ExsemanticaWeb.Endpoint},
      ExsemanticaWeb.EndpointApi,
      # Start Exsemnesia KV storage
      {Exsemnesia.Database,
       [
         tables: [
           {:users, ~w(node timestamp handle)a},
           {:posts, ~w(node timestamp handle title content posted_by)a},
           {:interests, ~w(node timestamp handle title content related_to)a},
           {:counters, ~w(type count)a}
         ],
         caches: [
           # This is weird. You can botch a composite key. Cool!
           {:ctrending, ~w(count_node node type htimestamp handle)a}
         ],
         tcopts: %{
           extra_indexes: %{
             users: ~w(handle)a,
             posts: ~w(handle)a,
             interests: ~w(handle)a,
             ctrending: ~w(node)a
           },
           ordered_caches: ~w(ctrending)a
         }
       ]}
      # Start a worker by calling: Exsemantica.Worker.start_link(arg)
      # {Exsemantica.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Exsemantica.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configurations
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ExsemanticaWeb.Endpoint.config_change(changed, removed)
    ExsemanticaWeb.EndpointApi.config_change(changed, removed)
    :ok
  end
end
