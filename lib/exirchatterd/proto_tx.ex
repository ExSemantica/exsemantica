defmodule Exirchatterd.ProtoTX do
  @moduledoc """
  Protocol specifics for IRC on the transmitting-end.
  """
  def send(state, socket, packet) do
    if state.ssl? do
      :ssl.send(socket, packet |> Exirchatterd.IRCPacket.decode())
    else
      :gen_tcp.send(socket, packet |> Exirchatterd.IRCPacket.decode())
    end

    state
  end

  def close(state, socket) do
    if state.ssl? do
      :ssl.close(socket)
    else
      :gen_tcp.close(socket)
    end

    state
  end
end
