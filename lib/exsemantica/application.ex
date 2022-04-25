defmodule Exsemantica.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @serv_opts [:binary, packet: :line, active: true, packet_size: 510, reuseaddr: true]

  @impl true
  def start(_type, _args) do
    cdate_path = Path.join([Application.app_dir(:exsemantica, "priv"), "Exsemantica_CDATE.erl"])

    # read off Creation Date for IRC standard requirement...ugh
    :persistent_term.put(
      Exsemantica.CDate,
      case :file.consult(cdate_path) do
        {:ok, [cdate]} ->
          cdate

        _ ->
          cdate = DateTime.utc_now()
          File.write(cdate_path, :io_lib.format("~p.~n", [Term]))
          cdate
      end
    )

    # then read off the Commit SHA or none at all...
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
      # Start the PubSub system
      {Phoenix.PubSub, name: Exsemantica.PubSub},
      # Start the Endpoints (http/https)
      ExsemanticaWeb.Endpoint,
      ExsemanticaWeb.EndpointApi,
      {Absinthe.Subscription, ExsemanticaWeb.EndpointApi},
      # Start Exsemnesia KV storage
      {Exsemnesia.Database,
       [
         tables: %{
           users: ~w(node timestamp handle privmask)a,
           posts: ~w(node timestamp handle title content posted_by)a,
           interests: ~w(node timestamp handle title content related_to)a,
           auth: ~w(handle secret token)a,
           counters: ~w(type count)a
         },
         caches: %{
           # This is weird. You can botch a composite key. Cool!
           ctrending: ~w(count_node node type htimestamp handle)a,
           lowercases: ~w(handle lowercase)a,
           # Exirchatterd augmentations require exsemnesia caches to share state
           irc_idling: ~w(handle modes_list)a,
           irc_inroom: ~w(room modes_list users_list)a
         },
         tcopts: %{
           extra_indexes: %{
             users: ~w(handle)a,
             posts: ~w(handle)a,
             interests: ~w(handle)a,
             ctrending: ~w(node)a,
             lowercases: ~w(lowercase)a
           },
           ordered_caches: ~w(ctrending)a,
           seed_trends: ~w(users posts interests)a,
           seed_seeder: fn entry ->
             {table, id, handle} =
               case entry do
                 {:users, id, _timestamp, handle, _privmask} ->
                   {:users, id, handle}

                 {:posts, id, _timestamp, handle, _title, _content, _posted_by} ->
                   {:posts, id, handle}

                 {:interests, id, _timestamp, handle, _title, _content, _related_to} ->
                   {:interests, id, handle}
               end

             :mnesia.write(
               :ctrending,
               {:ctrending, {0, id}, id, table, DateTime.utc_now(), handle},
               :sticky_write
             )

             :mnesia.write(
               :lowercases,
               {:lowercases, handle, String.downcase(handle, :ascii)},
               :sticky_write
             )
           end
         }
       ]},
      ExsemanticaWeb.AnnounceServer,
      Exirchatterd.Dial.DynamicSupervisor
      # Start a worker by calling: Exsemantica.Worker.start_link(arg)
      # {Exsemantica.Worker, arg}
    ]

    :persistent_term.put(:exseminvite, :crypto.strong_rand_bytes(24))
    :persistent_term.put(:exsemprefs, %{registration_enabled: true})

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Exsemantica.Supervisor]
    # which came first, the chicken or the egg
    state = Supervisor.start_link(children, opts)

    {:ok, listen} = :gen_tcp.listen(6667, @serv_opts)
    Exirchatterd.Dial.DynamicSupervisor.spawn_connection(listen, ssl: false)

    {:ok, ssl_listen} =
      :ssl.listen(
        6697,
        [
          [
            keyfile: Path.join([Application.app_dir(:exsemantica, "priv"), "snake.pem"]),
            certfile: Path.join([Application.app_dir(:exsemantica, "priv"), "snake.public.pem"])
          ]
          | @serv_opts
        ]
      )

    Exirchatterd.Dial.DynamicSupervisor.spawn_connection(ssl_listen, ssl: true)
    state
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
