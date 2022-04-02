defmodule Exirchatterd.CannedReplies do
  @moduledoc """
  ircd numerics...convert down to a string using Exirchatterd.IRCPacket.stringify/1
  """
  def reply(sta, 1) do
    %Exirchatterd.IRCPacket{
      prefix: ExsemanticaWeb.Endpoint.struct_url()[:host],
      command: "001",
      args_head: [sta.nick],
      args_tail:
        "Welcome to an Exsemantica IRC (Internet Relay Chat) cluster, #{sta.nick}!#{sta.ident}@#{sta.hostent}"
    }
  end

  def reply(sta, 2) do
    %Exirchatterd.IRCPacket{
      prefix: ExsemanticaWeb.Endpoint.struct_url()[:host],
      command: "002",
      args_head: [sta.nick],
      args_tail:
        "Your host is #{ExsemanticaWeb.Endpoint.struct_url()[:host]}, running Exsemantica v#{:persistent_term.get(Exsemantica.Version)}"
    }
  end

  def reply(sta, 375) do
    %Exirchatterd.IRCPacket{
      prefix: ExsemanticaWeb.Endpoint.struct_url()[:host],
      command: "375",
      args_head: [sta.nick],
      args_tail: "#{ExsemanticaWeb.Endpoint.struct_url()[:host]} Message of the Day"
    }
  end

  def reply(sta, {372, line}) do
    %Exirchatterd.IRCPacket{
      prefix: ExsemanticaWeb.Endpoint.struct_url()[:host],
      command: "372",
      args_head: [sta.nick],
      args_tail: "- #{line}"
    }
  end

  def reply(sta, 376) do
    %Exirchatterd.IRCPacket{
      prefix: ExsemanticaWeb.Endpoint.struct_url()[:host],
      command: "376",
      args_head: [sta.nick],
      args_tail: "End of /MOTD command"
    }
  end
end
