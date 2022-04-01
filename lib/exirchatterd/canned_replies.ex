defmodule Exirchatterd.CannedReplies do
  @moduledoc """
  ircd numerics...convert down to a string using Exirchatterd.IRCPacket.stringify/1
  """
  def reply(sta, 1) do
    nick = Keyword.get(sta, :nick)

    %Exirchatterd.IRCPacket{
      prefix: inspect(node()),
      root: "001",
      stem: nick,
      postfix:
        "Welcome to an Exsemantica IRC (Internet Relay Chat) cluster, #{nick}!#{Keyword.get(sta, :ident)}@#{Keyword.get(sta, :hostent)}"
    }
  end

  def reply(sta, 2) do
    nick = Keyword.get(sta, :nick)

    %Exirchatterd.IRCPacket{
      prefix: inspect(node()),
      root: "002",
      stem: nick,
      postfix:
        "Your host is #{inspect(node())}, running Exsemantica v#{:persistent_term.get(Exsemantica.Version)}"
    }
  end
end
