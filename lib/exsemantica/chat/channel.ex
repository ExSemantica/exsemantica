defmodule Exsemantica.Chat.Channel do
  @moduledoc """
  IRC channel PubSub
  """
  alias Exsemantica.Chat

  import Ecto.Query

  use GenServer

  # ===========================================================================
  # Use these calls
  # ===========================================================================
  def start_link(args, name: name) do
    GenServer.start_link(__MODULE__, args, name: name)
  end

  def join(pid, joiner, on_success_pid) do
    GenServer.cast(pid, {:join, joiner, on_success_pid})
  end

  def part(pid, leaver, on_success_pid, reason \\ nil) do
    GenServer.cast(pid, {:part, leaver, on_success_pid, reason})
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

  # ===========================================================================
  # Callbacks
  # ===========================================================================
  @impl true
  def init(aggregate: aggregate) do
    case aggregate |> lookup do
      {:ok, info} ->
        {:ok,
         %{
           channel: "#" <> info.name,
           topic: info.description,
           sockets: %{},
           created: DateTime.utc_now() |> DateTime.to_unix()
         }}

      :not_found ->
        {:stop, :not_found}
    end
  end

  @impl true
  def handle_cast({:join, joiner, on_success_pid}, state) do
    if Map.has_key?(state.sockets, joiner.socket) do
      # we're already in the channel
      {:noreply, state}
    else
      # get joining user's info
      [{_socket, joiner_state}] = Registry.lookup(Chat.Registry, joiner.socket)

      # add the user to the socket list
      state = put_in(state, [:sockets, joiner.socket], joiner)

      # send the join message to everyone
      for {_, s} <- state.sockets do
        s |> on_join(state.channel, joiner_state)
      end

      # send topic to joined user, then send people in channel to joined user
      joiner
      |> on_send_topic(state.channel, joiner_state, state.topic, state.created)
      |> on_send_names(state.channel, joiner_state, state.sockets)

      Chat.successful_join(on_success_pid, self(), joiner.socket)

      {:noreply, state}
    end
  end

  @impl true
  def handle_cast({:part, leaver, on_success_pid, reason}, state) do
    # get leaving user's info
    [{_socket, leaver_state}] = Registry.lookup(Chat.Registry, leaver.socket)

    if Map.has_key?(state.sockets, leaver.socket) do
      # we're in the channel
      for {_, s} <- state.sockets do
        s |> on_part(state.channel, leaver_state, reason)
      end

      Chat.successful_quit(on_success_pid, self(), leaver.socket)

      {_, state} = pop_in(state, [:sockets, leaver.socket])

      {:noreply, state}
    else
      # we're not in the channel
      leaver
      |> on_user_not_on_channel(state.channel, leaver_state)

      {:noreply, state}
    end
  end

  @impl true
  def handle_cast({:quit, quitter}, state) do
    # We already sent a quit message

    {_, state} = pop_in(state, [:sockets, quitter.socket])

    {:noreply, state}
  end

  @impl true
  def handle_cast({:send, talker, message}, state) do
    # get talking user's info
    [{_socket, talker_state}] = Registry.lookup(Chat.Registry, talker.socket)

    if Map.has_key?(state.sockets, talker.socket) do
      # we're in the channel
      receivers =
        state.sockets
        |> Map.delete(talker.socket)

      for {_, s} <- receivers do
        s |> on_talk(state.channel, talker_state, message)
      end

      {:noreply, state}
    else
      # we're not in the channel

      # this isn't IRC spec but we can sway things, all channels can't accept
      # external messages
      talker
      |> on_user_not_on_channel(state.channel, talker_state)

      {:noreply, state}
    end
  end

  @impl true
  def handle_call(:get_users, _from, state) do
    {:reply, state.sockets, state}
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
        trailing: "Test User"
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
        command: "442",
        params: [parter_state.handle, channel],
        trailing: "You're not on that channel"
      }
      |> Chat.Message.encode()
    )

    socket
  end

  defp on_send_topic(socket, channel, my_state, topic, refreshed) do
    burst = [
      %Chat.Message{
        command: "332",
        params: [my_state.handle, channel],
        trailing: topic
      },
      %Chat.Message{
        command: "333",
        params: [my_state.handle, channel, "Services", refreshed]
      }
    ]

    for b <- burst do
      socket
      |> ThousandIsland.Socket.send(b |> Chat.Message.encode())
    end

    socket
  end

  defp on_send_names(socket, channel, my_state, everyone) do
    handles =
      everyone
      |> Enum.map_join(" ", fn {_, s} ->
        [{_socket, s_state}] = Registry.lookup(Chat.Registry, s.socket)
        s_state.handle
      end)

    burst = [
      %Chat.Message{
        command: "353",
        params: [my_state.handle, "=", channel],
        trailing: handles
      },
      %Chat.Message{
        command: "366",
        params: [my_state.handle, channel],
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
    info =
      Exsemantica.Repo.one(
        from(a in Exsemantica.Repo.Aggregate, where: ilike(a.name, ^aggregate))
      )

    case info do
      %Exsemantica.Repo.Aggregate{name: name, description: description} ->
        {:ok, %{name: name, description: description}}

      nil ->
        :not_found
    end
  end
end
