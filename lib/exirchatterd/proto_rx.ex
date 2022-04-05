defmodule Exirchatterd.ProtoRX do
  @moduledoc """
  Protocol specifics for IRC on the receiving-end.
  """
  require Logger

  def route(
        %Exirchatterd.IRCPacket{
          prefix: _prefix,
          command: :nick,
          args_head: [nick],
          args_tail: _tail
        },
        _socket,
        state
      ) do
    {:noreply,
     unless state.nick? do
       state
       |> put_in(~w(data nickname)a, nick)
       |> put_in(~w(nick?)a, true)
     else
       state
     end}
  end

  def route(
        %Exirchatterd.IRCPacket{
          prefix: _prefix,
          command: :user,
          args_head: [ident, _, _],
          args_tail: real
        },
        socket,
        state
      ) do
    {:noreply,
     unless state.user? do
       state
       |> put_in(~w(data ident)a, ident)
       |> put_in(~w(data realname)a, real)
       |> put_in(~w(user?)a, true)
       |> motd(socket)
     else
       state
     end}
  end

  def route(packet, _socket, state) do
    Logger.warning("Unknown IRC packet #{inspect(packet)}")
    {:noreply, state}
  end

  def motd(state, socket) do
    hosts = ExsemanticaWeb.Endpoint.struct_url()
    host = hosts.host
    nick = state |> get_in(~w(data nickname)a)
    hostname = state |> get_in(~w(data hostname)a)
    ident = state |> get_in(~w(data ident)a)
    realname = state |> get_in(~w(data realname)a)

    state
    |> Exirchatterd.ProtoTX.send(socket, %Exirchatterd.IRCPacket{
      prefix: host,
      command: "001",
      args_head: [nick],
      args_tail:
        "Welcome to an Exsemantica IRC (Internet Relay Chat) cluster, #{nick}!#{ident}@#{hostname}"
    })

    {:noreply, state}
  end
end
