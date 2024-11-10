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

  # Wait this long in milliseconds for NICK and PASS before disconnecting
  # Note that USER isn't implemented here
  @timeout_auth 10_000

  # Ping interval in milliseconds
  @ping_interval 60_000

  # Maximum users who can join
  # TODO: Make this a config variable
  @max_users 1024

  # ===========================================================================
  # Initial connection
  # ===========================================================================
  @impl ThousandIsland.Handler
  def handle_connection(socket, state) do
    {:continue,
     %{
       state
       | requested_handle: nil,
         requested_password: nil,
         irc_state: :authentication,
         ping_timer: nil,
         user_data: nil
     }, @timeout_auth}
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
  def handle_data(data, socket, state = %{irc_state: irc_state, ping_timer: ping_timer}) do
    # Decode all receivable messages
    messages = data |> __MODULE__.Message.decode()

    # and then iterate through them
    for message <- messages do
      process_state(message, socket)
    end

    # What is our IRC state at the moment?
    case irc_state do
      :pinging ->
        Process.cancel_timer(ping_timer)

        {:continue,
         %{
           state
           | irc_state: :wait_for_ping,
             ping_timer: Process.send_after(self(), :ping, @ping_interval)
         }, :infinity}

      _ ->
        {:continue, state, socket.read_timeout}
    end
  end

  @impl ThousandIsland.Handler
  def handle_close(socket, %{user_data: user_data}) do
    __MODULE__.User.stop()

    :ok
  end

  @impl ThousandIsland.Handler
  def handle_timeout(socket, %{irc_state: irc_state}) do
    case irc_state do
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
  defp process_state(%__MODULE__.Message{command: "PING"}, socket) do
    socket
    |> ThousandIsland.Socket.send(
      %__MODULE__.Message{
        prefix: ApplicationInfo.get_chat_hostname(),
        command: "PONG"
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
    count = Registry.count(__MODULE__.Registry)

    case user do
      {:ok, user_data} when count <= @max_users ->
        # Runes to select all values
        collision? =
          Registry.select(__MODULE__.Registry, [{{:"$1", :"$2", :"$3"}, [], [:"$3"]}])
          |> Enum.any?(fn v ->
            h1 = v.handle |> String.downcase()
            h2 = user_data.username |> String.downcase()

            h1 == h2 && :ok == v.password
          end)

        if collision? do
          socket
          |> ThousandIsland.Socket.send(
            %__MODULE__.Message{
              prefix: ApplicationInfo.get_chat_hostname(),
              command: "433",
              params: [user_data.username],
              trailing: "Nickname is already in use"
            }
            |> __MODULE__.Message.encode()
          )

          socket |> quit(socket_state, "Nickname is already in use")
        else
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
        end

      {:ok, _} ->
        socket |> quit(socket_state, "Too many users on this server")

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
