defmodule Exsemantica.Chat.User do
  @moduledoc """
  Holds state of a specific user logged into IRC.
  """
  use Agent
  alias Exsemantica.Chat

  def start_link(_init_arg, handle: handle) do
    where = {:via, Registry, {Chat.UserRegistry, handle |> String.downcase()}}

    Agent.start_link(
      fn ->
        %{handle: handle, channels: MapSet.new()}
      end,
      name: where
    )
  end

  def channel_join(pid, channel) do
    Agent.update(pid, fn state ->
      %{state | channels: state.channels |> MapSet.put(channel)}
    end)
  end

  def channel_leave(pid, channel) do
    Agent.update(pid, fn state ->
      %{state | channels: state.channels |> MapSet.delete(channel)}
    end)
  end

  def stop(pid) do
    Agent.stop(pid)
  end
end
