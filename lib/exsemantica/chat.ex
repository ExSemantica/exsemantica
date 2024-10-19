defmodule Exsemantica.Chat do
  @moduledoc """
  IRC-compatible TCP-based chat server.

  Users can log in with a nickname and password. There is no need for the USER
  command to be sent.
  """
  alias Exsemantica.ApplicationInfo
  alias Exsemantica.Authentication
  alias Exsemantica.Constrain
  use ThousandIsland.Handler
  require Logger

  # Wait this long in milliseconds for NICK and PASS before disconnecting
  # Note that USER isn't implemented here
  @timeout_auth 10_000

  # Ping interval in milliseconds
  @ping_interval 60_000

  defmodule SocketState do
    @moduledoc """
    Stored in the registry with the ThousandIsland socket as the key
    """

    defstruct [:state, :handle, :password, :user_id, :vhost, :ping_timer, :channels]
  end

  @deprecated "Use state get/put functions instead."
  def successful_join(pid, channel, key) do
    GenServer.cast(pid, {:successful_join, channel, key})
  end

  @deprecated "Use state get/put functions instead."
  def successful_quit(pid, channel, key) do
    GenServer.cast(pid, {:successful_quit, channel, key})
  end

  @doc """
  Gets the registry state of a certain socket
  """
  def get_state(pid, key, reply_to) do
    GenServer.cast(pid, {:get_state, key, reply_to})
  end

  @doc """
  Puts a new registry state in the socket
  """
  def put_state(pid, key, what) do
    GenServer.cast(pid, {:put_state, key, what})
  end

  # ===========================================================================
  # Initial connection
  # ===========================================================================
  @impl ThousandIsland.Handler
  def handle_connection(socket, state) do
    {:ok, _pid} =
      Registry.register(__MODULE__.Registry, socket.socket, %__MODULE__.SocketState{
        state: :authentication,
        ping_timer: Process.send_after(self(), :ping, @ping_interval),
        channels: MapSet.new()
      })

    {:continue, state, @timeout_auth}
  end

  # ===========================================================================
  # Only our process can modify its own registry
  # ===========================================================================
  @impl GenServer
  def handle_cast({:successful_join, channel, key}, {socket, state}) do
    Registry.update_value(
      __MODULE__.Registry,
      key,
      &%__MODULE__.SocketState{&1 | channels: MapSet.put(&1.channels, channel)}
    )

    {:noreply, {socket, state}, socket.read_timeout}
  end

  @impl GenServer
  def handle_cast({:successful_quit, channel, key}, {socket, state}) do
    Registry.update_value(
      __MODULE__.Registry,
      key,
      &%__MODULE__.SocketState{&1 | channels: MapSet.delete(&1.channels, channel)}
    )

    {:noreply, {socket, state}, socket.read_timeout}
  end

  @impl GenServer
  def handle_cast({:get_state, key, reply_to}, {socket, state}) do
    [{_socket, socket_state}] = Registry.lookup(__MODULE__.Registry, key)

    Process.send(reply_to, {:socket_state, {key, socket_state}}, [])

    {:noreply, {socket, state}, socket.read_timeout}
  end

  @impl GenServer
  def handle_cast({:put_state, key, fun}, {socket, state}) do
    Registry.update_value(__MODULE__.Registry, key, fun)

    {:noreply, {socket, state}, socket.read_timeout}
  end

  # ===========================================================================
  # Info messages
  # ===========================================================================
  @impl GenServer
  def handle_info(:ping, {socket, state}) do
    socket
    |> ThousandIsland.Socket.send(
      %__MODULE__.Message{command: "PING", trailing: ApplicationInfo.get_chat_hostname()}
      |> __MODULE__.Message.encode()
    )

    {:noreply, {socket, state}, 5000}
  end

  # ===========================================================================
  # Receiving data
  # ===========================================================================
  @impl ThousandIsland.Handler
  def handle_data(data, socket, state) do
    # Decode all receivable messages
    messages = data |> __MODULE__.Message.decode()

    # and then iterate through them
    for message <- messages do
      {:ok, peer} = socket |> ThousandIsland.Socket.peername()
      Logger.debug(inspect(message, peer: peer))
      process_state(message, socket)
    end

    [{_socket, socket_state}] = Registry.lookup(__MODULE__.Registry, socket.socket)

    if socket_state.state == :pinging do
      Process.cancel_timer(socket_state.ping_timer)

      Registry.update_value(
        __MODULE__.Registry,
        socket.socket,
        &%__MODULE__.SocketState{
          &1
          | state: :wait_for_ping,
            ping_timer: Process.send_after(self(), :ping, @ping_interval)
        }
      )

      {:continue, state, :infinity}
    else
      {:continue, state, socket.read_timeout}
    end
  end

  @impl ThousandIsland.Handler
  def handle_close(socket, _state) do
    Registry.unregister(__MODULE__.Registry, socket.socket)

    :ok
  end

  @impl ThousandIsland.Handler
  def handle_timeout(socket, _state) do
    [{_socket, socket_state}] = Registry.lookup(__MODULE__.Registry, socket.socket)

    case socket_state.state do
      :authentication ->
        socket
        |> ThousandIsland.Socket.send(
          %__MODULE__.Message{command: "ERROR", trailing: "You did not authenticate on time"}
          |> __MODULE__.Message.encode()
        )

      :wait_for_ping ->
        socket
        |> quit(socket_state, "Ping timeout")
    end

    :ok
  end

  # ===========================================================================
  # Reducing state machine
  # ===========================================================================
  # NICK
  defp process_state(%__MODULE__.Message{command: "NICK", params: [nick]}, socket) do
    [{_socket, socket_state}] = Registry.lookup(__MODULE__.Registry, socket.socket)

    case nick |> Constrain.into_valid_username() do
      {:ok, valid_nick} when socket_state.state == :authentication ->
        Registry.update_value(
          __MODULE__.Registry,
          socket.socket,
          &%__MODULE__.SocketState{
            &1
            | handle: valid_nick
          }
        )

        [{_socket, socket_state}] = Registry.lookup(__MODULE__.Registry, socket.socket)

        if not is_nil(socket_state.password) and not is_nil(socket_state.handle) do
          socket |> try_login
        end
    end

    socket
  end

  # PASS
  defp process_state(%__MODULE__.Message{command: "PASS", params: [pass]}, socket) do
    [{_socket, socket_state}] = Registry.lookup(__MODULE__.Registry, socket.socket)

    if socket_state.state == :authentication do
      Registry.update_value(
        __MODULE__.Registry,
        socket.socket,
        &%__MODULE__.SocketState{
          &1
          | password: pass
        }
      )

      [{_socket, socket_state}] = Registry.lookup(__MODULE__.Registry, socket.socket)

      if not is_nil(socket_state.password) and not is_nil(socket_state.handle) do
        socket |> try_login
      end
    end

    socket
  end

  # PING
  defp process_state(%__MODULE__.Message{command: "PING", params: params}, socket) do
    socket
    |> ThousandIsland.Socket.send(
      %__MODULE__.Message{
        command: "PONG",
        params: params
      }
      |> __MODULE__.Message.encode()
    )

    socket
  end

  # PONG
  defp process_state(%__MODULE__.Message{command: "PONG"}, socket) do
    Registry.update_value(
      __MODULE__.Registry,
      socket.socket,
      &%__MODULE__.SocketState{&1 | state: :pinging}
    )

    socket
  end

  # JOIN
  defp process_state(%__MODULE__.Message{command: "JOIN", params: channels}, socket) do
    [{_socket, socket_state}] = Registry.lookup(__MODULE__.Registry, socket.socket)

    for channel <- channels do
      join_stat =
        __MODULE__.ChannelSupervisor.start_child(channel)

      case join_stat do
        {:ok, pid} ->
          __MODULE__.Channel.join(pid, socket, self())

        {:error, {:already_started, pid}} ->
          __MODULE__.Channel.join(pid, socket, self())

        {:error, :not_found} ->
          socket
          |> ThousandIsland.Socket.send(
            %__MODULE__.Message{
              command: "403",
              params: [socket_state.handle, channel],
              trailing: "No such channel/aggregate"
            }
            |> __MODULE__.Message.encode()
          )
      end
    end

    socket
  end

  # PART
  defp process_state(
         %__MODULE__.Message{command: "PART", params: channels, trailing: reason},
         socket
       ) do
    [{_socket, socket_state}] = Registry.lookup(__MODULE__.Registry, socket.socket)

    for channel <- channels do
      case Registry.lookup(
             __MODULE__.ChannelRegistry,
             channel |> String.downcase()
           ) do
        [{pid, _name}] ->
          __MODULE__.Channel.part(pid, socket, self(), reason)

        [] ->
          socket
          |> ThousandIsland.Socket.send(
            %__MODULE__.Message{
              prefix: ApplicationInfo.get_chat_hostname(),
              command: "403",
              params: [socket_state.handle, channel],
              trailing: "No such channel/aggregate"
            }
            |> __MODULE__.Message.encode()
          )
      end
    end

    socket
  end

  # PRIVMSG
  defp process_state(
         %__MODULE__.Message{command: "PRIVMSG", params: channels, trailing: message},
         socket
       ) do
    [{_socket, socket_state}] = Registry.lookup(__MODULE__.Registry, socket.socket)

    for channel <- channels do
      case Registry.lookup(
             __MODULE__.ChannelRegistry,
             channel |> String.downcase()
           ) do
        [{pid, _name}] ->
          __MODULE__.Channel.send(pid, socket, self(), message)

        [] ->
          socket
          |> ThousandIsland.Socket.send(
            %__MODULE__.Message{
              prefix: ApplicationInfo.get_chat_hostname(),
              command: "403",
              params: [socket_state.handle, channel],
              trailing: "No such channel/aggregate"
            }
            |> __MODULE__.Message.encode()
          )
      end
    end

    socket
  end

  # TODO: Add WHO command, might make HexChat happy
  # TODO: Add IRC chanop commands based on aggregate moderator listings

  # Undefined command
  defp process_state(_message, socket) do
    socket
  end

  # ===========================================================================
  # Login
  # ===========================================================================
  defp try_login(socket) do
    [{_socket, socket_state}] = Registry.lookup(__MODULE__.Registry, socket.socket)

    user = Authentication.check_user(socket_state.handle, socket_state.password)

    case user do
      {:ok, user_data} ->
        Registry.update_value(
          __MODULE__.Registry,
          socket.socket,
          &%__MODULE__.SocketState{
            &1
            | handle: user_data.username,
              password: :ok,
              user_id: user_data.username,
              vhost: "user/" <> user_data.username,
              state: :pinging
          }
        )

        vsn = ApplicationInfo.get_version()

        refreshed =
          ApplicationInfo.get_last_refreshed() |> Calendar.strftime("%a, %-d %b %Y %X %Z")

        burst = [
          %__MODULE__.Message{
            prefix: ApplicationInfo.get_chat_hostname(),
            command: "001",
            params: [socket_state.handle],
            trailing: "Welcome to ExSemantica chat, #{socket_state.handle}"
          },
          %__MODULE__.Message{
            prefix: ApplicationInfo.get_chat_hostname(),
            command: "002",
            params: [socket_state.handle],
            trailing:
              "Your host is #{ApplicationInfo.get_chat_hostname()}, running version #{vsn}"
          },
          %__MODULE__.Message{
            prefix: ApplicationInfo.get_chat_hostname(),
            command: "003",
            params: [socket_state.handle],
            trailing: "This server was last (re)started #{refreshed}"
          },
          %__MODULE__.Message{
            prefix: ApplicationInfo.get_chat_hostname(),
            command: "004",
            params: [socket_state.handle, "exsemantica", vsn]
          },
          # TODO: Add supported caps here
          %__MODULE__.Message{
            prefix: ApplicationInfo.get_chat_hostname(),
            command: "005",
            params: [socket_state.handle],
            trailing: "are supported by this server"
          },
          %__MODULE__.Message{
            prefix: ApplicationInfo.get_chat_hostname(),
            command: "422",
            params: [socket_state.handle],
            trailing: "MOTD File is unimplemented"
          }
        ]

        for b <- burst do
          socket |> ThousandIsland.Socket.send(b |> __MODULE__.Message.encode())
        end

        socket

      {:error, :unauthorized} ->
        socket |> quit(socket_state, "Incorrect username or password")

      {:error, :not_found} ->
        socket |> quit(socket_state, "User not found")
    end
  end

  # ===========================================================================
  # Quit
  # ===========================================================================
  defp quit(socket, socket_state, reason) do
    # This is complicated so I will explain how this all works

    # Get our channels
    quits =
      socket_state.channels
      # Get all users in that channel
      |> MapSet.to_list()
      |> Enum.map(fn pid ->
        pid |> __MODULE__.Channel.quit(socket)
        pid |> __MODULE__.Channel.get_users() |> Map.to_list()
      end)
      |> List.flatten()
      # Strip duplicate socket entries, we're not sending multiple QUITs
      |> Enum.reduce(%{}, fn {k, v}, acc ->
        if Map.has_key?(acc, k) do
          acc
        else
          acc |> Map.put(k, v)
        end
      end)

    # Finally send the QUIT messages
    for {_, sock} <- quits do
      sock
      |> ThousandIsland.Socket.send(
        %__MODULE__.Message{
          prefix: socket_state |> __MODULE__.HostMask.get(),
          command: "QUIT",
          trailing: reason
        }
        |> __MODULE__.Message.encode()
      )
    end

    # Notify the client of the connection termination reason
    socket
    |> ThousandIsland.Socket.send(
      %__MODULE__.Message{
        command: "ERROR",
        trailing: reason
      }
      |> __MODULE__.Message.encode()
    )

    # Close the client socket, the handle_close callback will wipe the socket
    # from the Registry
    socket |> ThousandIsland.Socket.close()
  end
end
