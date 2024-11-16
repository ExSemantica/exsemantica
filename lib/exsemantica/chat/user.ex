defmodule Exsemantica.Chat.User do
  @moduledoc """
  Holds state of a specific user logged into IRC.
  """
  use Agent
  alias Exsemantica.Chat

  @doc """
  Initializes this user's state
  """
  def start_link(_init_arg, handle: handle, socket: socket) do
    where = {:via, Registry, {Chat.UserRegistry, handle}}

    Agent.start_link(
      fn ->
        %{handle: handle, socket: socket, channels: MapSet.new(), modes: MapSet.new()}
      end,
      name: where
    )
  end

  @doc """
  Gets this user's handle
  """
  def get_handle(pid) do
    Agent.get(pid, & &1.handle)
  end

  @doc """
  Gets a list of the channels this user's in
  """
  def get_channels(pid) do
    Agent.get(pid, &(&1.channels |> MapSet.to_list()))
  end

  @doc """
  Gets the usermodes this user has
  """
  def get_modes(pid) do
    Agent.get(pid, &(&1.modes |> MapSet.to_list() |> to_string()))
  end

  @doc """
  Modifies this user's usermodes

  TODO: doctest this
  """
  def set_modes(pid, modes) do
    Agent.update(pid, fn state ->
      modes
      |> Enum.reduce(state, &chunk_modes/2)
    end)
  end

  @doc """
  Helper for sending wallops

  This should not be called on its own
  Please use `Exsemantica.Administration.Chat.wallops/1` for this instead.
  """
  def wallops(pid, message) do
    Agent.get(pid, fn state ->
      if state.modes |> MapSet.member?(?w) do
        Chat.wallops(state.socket, message)
      end
    end)
  end

  @doc """
  Makes this user join a channel

  This should not be called on its own
  """
  def join(pid, channel) do
    Agent.update(pid, fn state ->
      %{state | channels: state.channels |> MapSet.put(channel)}
    end)
  end

  @doc """
  Makes this user part a channel

  This should not be called on its own.
  """
  def part(pid, channel) do
    Agent.update(pid, fn state ->
      %{state | channels: state.channels |> MapSet.delete(channel)}
    end)
  end

  @doc """
  Helper for forcefully disconnecting this user

  This should not be called on its own
  Please use `Exsemantica.Administration.Chat.kill_client/2` for this instead.
  """
  def kill_connection(pid, source, reason) do
    Agent.get(pid, fn state ->
      Chat.kill_client(state.socket, source, reason)
    end)
  end

  @doc """
  Sends a PRIVMSG to this user

  This should not be called on its own
  """
  def send(pid, talker, message) do
    Agent.get(pid, fn state ->
      Chat.direct_message(state.socket, talker, message)
    end)
  end

  # ===========================================================================
  # Private functions go here
  # ===========================================================================
  defp chunk_modes(mode_chunk, state) do
    # Charlist so that you can iterate through each mode point
    [chead | ctail] = mode_chunk |> String.to_charlist()

    case chead do
      # Adds usermodes
      ?+ ->
        ctail |> Enum.reduce(state, &add_modes/2)

      # Removes usermodes
      ?- ->
        ctail |> Enum.reduce(state, &del_modes/2)

      # Something unimplemented
      _ ->
        state
    end
  end

  defp add_modes(?w, state) do
    %{state | modes: MapSet.put(state.modes, ?w)}
  end

  defp add_modes(_mode_char, state) do
    state
  end

  defp del_modes(?w, state) do
    %{state | modes: MapSet.delete(state.modes, ?w)}
  end

  defp del_modes(_mode_char, state) do
    state
  end
end
