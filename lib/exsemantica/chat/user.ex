defmodule Exsemantica.Chat.User do
  @moduledoc """
  Holds state of a specific user logged into IRC.
  """
  use Agent
  alias Exsemantica.Chat

  def start_link(_init_arg, handle: handle, socket: socket) do
    where = {:via, Registry, {Chat.UserRegistry, handle}}

    Agent.start_link(
      fn ->
        %{handle: handle, socket: socket, channels: MapSet.new()}
      end,
      name: where
    )
  end

  def get_handle(pid) do
    Agent.get(pid, & &1.handle)
  end

  def get_channels(pid) do
    Agent.get(pid, &(&1.channels |> MapSet.to_list()))
  end

  def join(pid, channel) do
    Agent.update(pid, fn state ->
      %{state | channels: state.channels |> MapSet.put(channel)}
    end)
  end

  def part(pid, channel) do
    Agent.update(pid, fn state ->
      %{state | channels: state.channels |> MapSet.delete(channel)}
    end)
  end

  def kill_connection(pid, source, reason) do
    socket_pid = Agent.get(pid, fn state ->
      state.socket
    end)

    Chat.kill_client(socket_pid, source, reason)
  end
end
