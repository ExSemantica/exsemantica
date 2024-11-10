defmodule Exsemantica.Chat do
  @moduledoc """
  IRC-compatible TCP-based chat server.

  Users can log in with a nickname and password. There is no need for the USER
  command to be sent.
  """
  alias Exsemantica.ApplicationInfo
  alias Exsemantica.ApplicationInfo
  alias Exsemantica.Authentication
  alias Exsemantica.Constrain
  use ThousandIsland.Handler

  # Wait this long in milliseconds for NICK and PASS before disconnecting
  # Note that USER isn't implemented here
  @timeout_auth 10_000

  # Ping interval in milliseconds
  @ping_interval 60_000

  # ===========================================================================
  # Initial connection
  # ===========================================================================
  @impl ThousandIsland.Handler
  def handle_connection(_socket, state) do
    {:continue,
     %{state | 
       requested_handle: nil,
       requested_password: nil,
       irc_state: :authentication,
       ping_timer: nil,
       user_pid: nil,
       connected?: false
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
    {socket, state} =
      messages
      |> Enum.reduce({socket, state}, &process_state/2)

    # What is our IRC state at the moment?
    # NOTE: we can't update the read timeout using process_state
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
  def handle_close(_socket, %{user_pid: user_pid}) do
    if not is_nil(user_pid) do
      __MODULE__.User.stop(user_pid)
    end

    :ok
  end

  @impl ThousandIsland.Handler
  def handle_timeout(socket, state = %{irc_state: irc_state}) do
    case irc_state do
      # Authentication has timed out
      :authentication ->
        {socket, state}
        |> quit("Authentication timeout")

      # Ping has timed out
      :wait_for_ping ->
        {socket, state}
        |> quit("Ping timeout")
    end

    :ok
  end

  # ===========================================================================
  # Reducing state machine
  # ===========================================================================
  # NICK
  defp process_state(
         %__MODULE__.Message{command: "NICK", params: [nick]},
         {socket,
          state = %{
            irc_state: :authentication,
            requested_password: requested_password,
            requested_handle: requested_handle
          }}
       ) do
    case nick |> Constrain.into_valid_username() do
      {:ok, valid_nick} ->
        {socket, state} = {socket, %{state | requested_handle: valid_nick}}

        if not is_nil(requested_password) and not is_nil(requested_handle) do
          {socket, state} |> try_login()
        else
          {socket, state}
        end

      _error ->
        {socket, state}
        |> quit("Invalid handle")
    end
  end

  # PASS
  defp process_state(
         %__MODULE__.Message{command: "PASS", params: [pass]},
         {socket,
          state = %{
            irc_state: :authentication,
            requested_password: requested_password,
            requested_handle: requested_handle
          }}
       ) do
    {socket, state} = {socket, %{state | requested_password: pass}}

    if not is_nil(requested_password) and not is_nil(requested_handle) do
      {socket, state} |> try_login()
    else
      {socket, state}
    end
  end

  # PING
  defp process_state(%__MODULE__.Message{command: "PING"}, {socket, state}) do
    socket
    |> ThousandIsland.Socket.send(
      %__MODULE__.Message{
        prefix: ApplicationInfo.get_chat_hostname(),
        command: "PONG"
      }
      |> __MODULE__.Message.encode()
    )

    {socket, state}
  end

  # PONG
  defp process_state(%__MODULE__.Message{command: "PONG"}, {socket, state}) do
    {socket, %{state | irc_state: :pinging}}
  end

  # JOIN
  defp process_state(
         %__MODULE__.Message{command: "JOIN", params: [channels]},
         {socket, state = %{requested_handle: requested_handle, connected?: true}}
       ) do
    channels_split = channels |> String.split(",")

    for channel <- channels_split do
      join_stat =
        __MODULE__.ChannelSupervisor.start_child(channel)

      case join_stat do
        {:ok, pid} ->
          __MODULE__.Channel.join(pid, {socket, state})

        {:error, {:already_started, pid}} ->
          __MODULE__.Channel.join(pid, {socket, state})

        {:error, :not_found} ->
          socket
          |> ThousandIsland.Socket.send(
            %__MODULE__.Message{
              prefix: ApplicationInfo.get_chat_hostname(),
              command: "403",
              params: [requested_handle, channel],
              trailing: "No such channel/aggregate"
            }
            |> __MODULE__.Message.encode()
          )
      end
    end

    {socket, state}
  end

  # PART
  defp process_state(
         %__MODULE__.Message{command: "PART", params: channels, trailing: reason},
         {socket, state = %{requested_handle: requested_handle, connected?: true}}
       ) do
    channels_split = channels |> String.split(",")

    for channel <- channels_split do
      case Registry.lookup(__MODULE__.ChannelRegistry, channel) do
        [{pid, _name}] ->
          __MODULE__.Channel.part(pid, {socket, state}, reason)

        [] ->
          socket
          |> ThousandIsland.Socket.send(
            %__MODULE__.Message{
              prefix: ApplicationInfo.get_chat_hostname(),
              command: "403",
              params: [requested_handle, channel],
              trailing: "No such channel/aggregate"
            }
            |> __MODULE__.Message.encode()
          )
      end
    end

    {socket, state}
  end

  # PRIVMSG
  defp process_state(
         %__MODULE__.Message{command: "PRIVMSG", params: [channel], trailing: message},
         {socket, state = %{requested_handle: requested_handle, connected?: true}}
       ) do
    # TODO: Make it able to direct message users...
    case Registry.lookup(
           __MODULE__.ChannelRegistry,
           channel |> String.downcase()
         ) do
      [{pid, _name}] ->
        __MODULE__.Channel.send(pid, {socket, state}, message)

      [] ->
        socket
        |> ThousandIsland.Socket.send(
          %__MODULE__.Message{
            prefix: ApplicationInfo.get_chat_hostname(),
            command: "403",
            params: [requested_handle, channel],
            trailing: "No such channel/aggregate"
          }
          |> __MODULE__.Message.encode()
        )
    end

    {socket, state}
  end

  # TODO: Add WHO command, might make HexChat happy
  # TODO: Add IRC chanop commands based on aggregate moderator listings

  # Undefined command
  defp process_state(_message, {socket, state}) do
    {socket, state}
  end

  # ===========================================================================
  # Login
  # ===========================================================================
  defp try_login(
         {socket,
          state = %{requested_handle: requested_handle, requested_password: requested_password}}
       ) do
    user = Authentication.check_user(requested_handle, requested_password)

    case user do
      {:ok, user_data} ->
        user_stat = __MODULE__.UserSupervisor.start_child(user_data.handle)

        case user_stat do
          {:ok, user_pid} ->
            handle = __MODULE__.User.get_handle(user_pid)

            state = %{
              state
              | user_pid: user_pid,
                requested_handle: handle,
                requested_password: :ok,
                ident: "user",
                vhost: "user/" <> handle,
                connected?: true
            }

            # application version
            vsn = ApplicationInfo.get_version()

            # configured hostname
            host = ApplicationInfo.get_chat_hostname()

            # last refresh of IRC daemon
            refreshed =
              ApplicationInfo.get_last_refreshed() |> Calendar.strftime("%a, %-d %b %Y %X %Z")

            burst = [
              %__MODULE__.Message{
                prefix: host,
                command: "001",
                params: [handle],
                trailing: "Welcome to ExSemantica chat, #{handle}"
              },
              %__MODULE__.Message{
                prefix: host,
                command: "002",
                params: [handle],
                trailing: "Your host is #{host}, running version v#{vsn}"
              },
              %__MODULE__.Message{
                prefix: host,
                command: "003",
                params: [handle],
                trailing: "This server was last (re)started #{refreshed}"
              },
              %__MODULE__.Message{
                prefix: host,
                command: "004",
                params: [handle, "exsemantica", vsn]
              },
              # TODO: Add supported caps here
              %__MODULE__.Message{
                prefix: host,
                command: "005",
                params: [handle],
                trailing: "are supported by this server"
              },
              %__MODULE__.Message{
                prefix: host,
                command: "422",
                params: [handle],
                trailing: "MOTD File is unimplemented"
              }
            ]

            for b <- burst do
              socket |> ThousandIsland.Socket.send(b |> __MODULE__.Message.encode())
            end

            {socket, state}

          {:error, {:already_started, _pid}} ->
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

            {socket, state} |> quit("Nickname is already in use")

          {:error, :max_children} ->
            {socket, state} |> quit("Too many users online on this server")
        end

      {:error, :unauthorized} ->
        {socket, state} |> quit("Incorrect username or password")

      {:error, :not_found} ->
        {socket, state} |> quit("User not found")
    end
  end

  # ===========================================================================
  # Quit
  # ===========================================================================
  defp quit({socket, state = %{user_pid: user_pid}}, reason) do
    # This is complicated so I will explain how this all works
    if not is_nil(user_pid) do
      receiving_sockets =
        user_pid
        # Get a list of channels the user is connected to
        |> __MODULE__.User.get_channels()
        # Get a list of all sockets in all channels the user is in
        |> Enum.map(fn channel ->
          channel |> __MODULE__.Channel.quit({socket, state})
          others = channel |> __MODULE__.Channel.get_users()

          for {other_socket, _other_pid} <- others do
            other_socket
          end
        end)
        # We need to flatten it since it's a list of lists
        |> List.flatten()
        # Remove duplicates
        |> MapSet.new()
        # Convert to a list
        |> MapSet.to_list()

      for receiving_socket <- receiving_sockets do
        receiving_socket
        |> ThousandIsland.Socket.send(
          %__MODULE__.Message{
            prefix: state |> __MODULE__.HostMask.get(),
            command: "QUIT",
            trailing: reason
          }
          |> __MODULE__.Message.encode()
        )
      end
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

    # NOTE: Will this cause lingering states?
    {socket, state}
  end
end
