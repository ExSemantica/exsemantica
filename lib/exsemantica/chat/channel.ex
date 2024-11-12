defmodule Exsemantica.Chat.Channel do
  @moduledoc """
  IRC channel PubSub
  """
  alias Exsemantica.ApplicationInfo
  alias Exsemantica.Chat

  import Ecto.Query

  use GenServer

  # ===========================================================================
  # Use these calls
  # ===========================================================================
  def start_link(_init_arg, aggregate: aggregate) do
    where = {:via, Registry, {Chat.ChannelRegistry, aggregate}}
    GenServer.start_link(__MODULE__, [aggregate: aggregate], name: where)
  end

  def join(pid, joiner) do
    GenServer.cast(pid, {:join, joiner})
  end

  def part(pid, leaver, reason \\ nil) do
    GenServer.cast(pid, {:part, leaver, reason})
  end

  def send(pid, talker, message) do
    GenServer.cast(pid, {:send, talker, message})
  end

  def quit(pid, quitter) do
    GenServer.cast(pid, {:quit, quitter})
  end

  def get_users(pid) do
    GenServer.call(pid, :get_users)
  end

  def get_name(pid) do
    GenServer.call(pid, :get_name)
  end

  # ===========================================================================
  # Callbacks
  # ===========================================================================
  @impl true
  def init(aggregate: aggregate) do
    case aggregate |> lookup do
      {:ok, info} ->
        {:ok,
         %{
           channel: info.name |> String.downcase(),
           topic: info.description,
           users: [],
           created: DateTime.utc_now() |> DateTime.to_unix()
         }}

      :not_found ->
        {:stop, :not_found}
    end
  end

  @impl true
  def handle_cast(
        {:join, {joiner_socket, joiner_state = %{user_pid: user_pid}}},
        state = %{users: users, channel: channel, topic: topic, created: created}
      ) do
    if {joiner_socket, user_pid} in users do
      # we're already in the channel
      {:noreply, state}
    else
      # add the user to the socket list
      state = %{state | users: [{joiner_socket, user_pid} | users]}

      # send the join message to everyone
      for {other_socket, _other_pid} <- state.users do
        other_socket |> on_join(state.channel, joiner_state)
      end

      # send topic to joined user, then send people in channel to joined user
      joiner_socket
      |> on_send_topic(channel, joiner_state, topic, created)
      |> on_send_names(channel, joiner_state, state.users)

      Chat.User.join(user_pid, channel)

      {:noreply, state}
    end
  end

  @impl true
  def handle_cast(
        {:part, {leaver_socket, leaver_state = %{user_pid: user_pid}}, reason},
        state = %{users: users, channel: channel}
      ) do
    if {leaver_socket, user_pid} in users do
      # we're in the channel
      for {other_socket, _other_pid} <- users do
        other_socket |> on_part(channel, leaver_state, reason)
      end

      Chat.User.part(user_pid, channel)

      {:noreply, %{state | users: users |> List.delete({leaver_socket, user_pid})}}
    else
      # we're not in the channel
      leaver_socket
      |> on_user_not_on_channel(channel, leaver_state)

      {:noreply, state}
    end
  end

  @impl true
  def handle_cast({:quit, {quitter_socket, %{user_pid: user_pid}}}, state = %{users: users}) do
    # We already sent a quit message
    {:noreply, %{state | users: users |> List.delete({quitter_socket, user_pid})}}
  end

  @impl true
  def handle_cast(
        {:send, {talker_socket, talker_state = %{user_pid: user_pid}}, message},
        state = %{users: users, channel: channel}
      ) do
    if {talker_socket, user_pid} in users do
      # we're in the channel
      for {receiver_socket, receiver_pid} <- users do
        if user_pid != receiver_pid do
          receiver_socket |> on_talk(channel, talker_state, message)
        end
      end

      {:noreply, state}
    else
      # we're not in the channel

      # this isn't IRC spec but we can sway things, all channels can't accept
      # external messages
      talker_socket
      |> on_user_not_on_channel(channel, talker_state)

      {:noreply, state}
    end
  end

  @impl true
  def handle_call(:get_users, _from, state = %{users: users}) do
    {:reply, users, state}
  end

  @impl true
  def handle_call(:get_name, _from, state = %{channel: channel}) do
    {:reply, channel, state}
  end

  # ===========================================================================
  # Private miscellaneous callbacks
  # ===========================================================================
  defp on_join(socket, channel, joiner_state) do
    socket
    |> ThousandIsland.Socket.send(
      %Chat.Message{
        prefix: joiner_state |> Chat.HostMask.get(),
        command: "JOIN",
        params: [channel],
        trailing: "Exsemantica User"
      }
      |> Chat.Message.encode()
    )

    socket
  end

  defp on_part(socket, channel, parter_state, part_reason) do
    socket
    |> ThousandIsland.Socket.send(
      %Chat.Message{
        prefix: parter_state |> Chat.HostMask.get(),
        command: "PART",
        params: [channel],
        trailing: part_reason
      }
      |> Chat.Message.encode()
    )

    socket
  end

  defp on_talk(socket, channel, talker_state, message) do
    socket
    |> ThousandIsland.Socket.send(
      %Chat.Message{
        prefix: talker_state |> Chat.HostMask.get(),
        command: "PRIVMSG",
        params: [channel],
        trailing: message
      }
      |> Chat.Message.encode()
    )

    socket
  end

  defp on_user_not_on_channel(socket, channel, parter_state) do
    socket
    |> ThousandIsland.Socket.send(
      %Chat.Message{
        prefix: ApplicationInfo.get_chat_hostname(),
        command: "442",
        params: [parter_state.requested_handle, channel],
        trailing: "You're not on that channel"
      }
      |> Chat.Message.encode()
    )

    socket
  end

  defp on_send_topic(socket, channel, my_state, topic, refreshed) do
    handle = my_state.requested_handle
    burst = [
      %Chat.Message{
        prefix: ApplicationInfo.get_chat_hostname(),
        command: "332",
        params: [handle, channel],
        trailing: topic
      },
      %Chat.Message{
        prefix: ApplicationInfo.get_chat_hostname(),
        command: "333",
        params: [handle, channel, "Services", refreshed]
      }
    ]

    for b <- burst do
      socket
      |> ThousandIsland.Socket.send(b |> Chat.Message.encode())
    end

    socket
  end

  defp on_send_names(socket, channel, my_state, everyone) do
    handle = my_state.requested_handle

    handles =
      everyone
      |> Enum.map_join(" ", fn {_socket, user_pid} ->
        Chat.User.get_handle(user_pid)
      end)

    burst = [
      %Chat.Message{
        prefix: ApplicationInfo.get_chat_hostname(),
        command: "353",
        params: [handle, "=", channel],
        trailing: handles
      },
      %Chat.Message{
        prefix: ApplicationInfo.get_chat_hostname(),
        command: "366",
        params: [handle, channel],
        trailing: "End of /NAMES list"
      }
    ]

    for b <- burst do
      socket
      |> ThousandIsland.Socket.send(b |> Chat.Message.encode())
    end

    socket
  end

  defp lookup(aggregate) do
    aggregate = aggregate |> String.replace_prefix("#", "")

    info =
      Exsemantica.Repo.one(
        from(a in Exsemantica.Repo.Aggregate, where: ilike(a.name, ^aggregate))
      )

    case info do
      %Exsemantica.Repo.Aggregate{name: name, description: description} ->
        {:ok, %{name: "##{name}" |> String.downcase(), description: description}}

      nil ->
        :not_found
    end
  end
end
