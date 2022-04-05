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
    unless state.nick? do
      state
      |> put_in(~w(data nickname)a, nick)
      |> put_in(~w(nick?)a, true)
    else
      state
    end
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
    unless state.user? do
      state
      |> put_in(~w(data ident)a, ident)
      |> put_in(~w(data realname)a, real)
      |> put_in(~w(user?)a, true)
      |> motd(socket, true)
    else
      state
    end
  end

  def route(
        %Exirchatterd.IRCPacket{
          prefix: _prefix,
          command: :ping,
          args_head: args,
          args_tail: _tail
        },
        socket,
        state
      ) do
    state
    |> Exirchatterd.ProtoTX.send(socket, %Exirchatterd.IRCPacket{
      prefix: nil,
      command: :pong,
      args_head: args,
      args_tail: nil
    })

    state
  end

  def route(
        %Exirchatterd.IRCPacket{
          prefix: _prefix,
          command: :pong,
          args_head: _args,
          args_tail: _tail
        },
        socket,
        state
      ) do
    state |> get_in(~w(data ping_kill)a) |> Process.cancel_timer()
    Process.send_after(self(), {:chkping, socket}, Exirchatterd.Dial.Listener.ping_interval())
    state
  end

  def route(packet, _socket, state) do
    Logger.warning("Unknown IRC packet #{inspect(packet)}")
    state
  end

  def motd(state, socket, join?) do
    hosts = ExsemanticaWeb.Endpoint.struct_url()
    host = hosts.host
    nick = state |> get_in(~w(data nickname)a)
    hostname = state |> get_in(~w(data hostname)a)
    ident = state |> get_in(~w(data ident)a)
    # realname = state |> get_in(~w(data realname)a)
    date = :persistent_term.get(Exsemantica.CDate) |> DateTime.to_string()
    ver = :persistent_term.get(Exsemantica.Version)

    if join? do
      state
      |> Exirchatterd.ProtoTX.send(socket, %Exirchatterd.IRCPacket{
        prefix: host,
        command: "001",
        args_head: [nick],
        args_tail:
          "Welcome to an Exsemantica IRC (Internet Relay Chat) cluster, #{nick}!#{ident}@#{hostname}"
      })

      state
      |> Exirchatterd.ProtoTX.send(socket, %Exirchatterd.IRCPacket{
        prefix: host,
        command: "002",
        args_head: [nick],
        args_tail: "Your host is #{host}, running Exsemantica #{ver}"
      })

      state
      |> Exirchatterd.ProtoTX.send(socket, %Exirchatterd.IRCPacket{
        prefix: host,
        command: "003",
        args_head: [nick],
        args_tail: "This server was created #{date}"
      })

      state
      |> Exirchatterd.ProtoTX.send(socket, %Exirchatterd.IRCPacket{
        prefix: host,
        command: "004",
        args_head: [nick, host, ver],
        args_tail: nil
      })
    end

    _ = """
    User Modes
    i = invisible
    s = server notice recipient (whatever this will be...)
    w = wallop
    r = restricted guest who needs to authenticate
    o = IRC operator
    z = secure SSL connection

    Channel Modes
    o = operator
    b = ban ExSemantica Handle128s as hostcloaks
    v = voice ExSemantica Handle128s as hostcloaks
    """

    state
    |> Exirchatterd.ProtoTX.send(socket, %Exirchatterd.IRCPacket{
      prefix: host,
      command: "375",
      args_head: [nick],
      args_tail: "- #{host} Message of the Day -"
    })

    for motd <- Exirchatterd.MOTD.motd() |> String.split("\n") do
      state
      |> Exirchatterd.ProtoTX.send(socket, %Exirchatterd.IRCPacket{
        prefix: host,
        command: "372",
        args_head: [nick],
        args_tail: "- #{motd}"
      })
    end

    state
    |> Exirchatterd.ProtoTX.send(socket, %Exirchatterd.IRCPacket{
      prefix: host,
      command: "376",
      args_head: [nick],
      args_tail: "End of MOTD command"
    })
  end
end
