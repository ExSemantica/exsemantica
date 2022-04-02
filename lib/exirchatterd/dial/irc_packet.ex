defmodule Exirchatterd.IRCPacket do
  @moduledoc """
  Define the IRC packet structure per RFC2812
  """
  defstruct prefix: nil, command: nil, args_head: nil, args_tail: nil

  #   {prefix, root, stem, postfix} =
  #     if raw |> String.starts_with?(":") do
  #       case raw |> String.split(" ", parts: 4) do
  #         [raw_prefix, root, stem, raw_postfix] ->
  #           prefix = String.trim_leading(raw_prefix, ":")
  #           postfix = String.trim_leading(raw_postfix, ":")
  #           {prefix, root, stem, postfix}

  #         [raw_prefix, root, stem] ->
  #           prefix = String.trim_leading(raw_prefix, ":")
  #           {prefix, root, stem, nil}

  #         [raw_prefix, root] ->
  #           prefix = String.trim_leading(raw_prefix, ":")
  #           {prefix, root, nil, nil}
  #       end
  #     else
  #       case raw |> String.split(" ", parts: 3) do
  #         [root, stem, raw_postfix] ->
  #           postfix = String.trim_leading(raw_postfix, ":")
  #           {nil, root, stem, postfix}

  #         [root, stem] ->
  #           {nil, root, stem, nil}

  #         [root] ->
  #           {nil, root, nil, nil}
  #       end
  #     end

  #   %__MODULE__{
  #     prefix: prefix,
  #     root: root,
  #     stem: stem,
  #     postfix: postfix
  #   }
  # end

  # def stringify(st) do
  #   if not is_nil(st.prefix) do
  #     if not is_nil(st.postfix) do
  #       ":" <> Enum.join([st.prefix, st.root, st.stem, ":" <> st.postfix], " ") <> "\r\n"
  #     else
  #       Enum.join([st.prefix, st.root, st.stem], " ") <> "\r\n"
  #     end
  #   else
  #     if not is_nil(st.postfix) do
  #       Enum.join([st.root, st.stem, ":" <> st.postfix], " ") <> "\r\n"
  #     else
  #       Enum.join([st.root, st.stem], " ") <> "\r\n"
  #     end
  #   end
  # end
  def encode(data) do
    data = data |> String.replace_trailing("\r\n", "")

    {origin, head, tail} =
      if String.starts_with?(data, ":") do
        [head, tail] = String.split(data, " ", parts: 2)
        origin = String.replace_prefix(head, ":", "")
        {origin, head, tail}
      else
        [head, tail] = String.split(data, " ", parts: 2)
        {nil, head, tail}
      end

    verb =
      case String.upcase(head) do
        "PASS" ->
          :pass

        "NICK" ->
          :nick

        "USER" ->
          :user

        "OPER" ->
          :oper

        "MODE" ->
          :mode

        "SERVICE" ->
          :service

        "QUIT" ->
          :quit

        "SQUIT" ->
          :squit

        "JOIN" ->
          :join

        "PART" ->
          :part

        "TOPIC" ->
          :topic

        "NAMES" ->
          :names

        "LIST" ->
          :list

        "INVITE" ->
          :invite

        "KICK" ->
          :kick

        "PRIVMSG" ->
          :privmsg

        "NOTICE" ->
          :notice

        "SQUERY" ->
          :squery

        "MOTD" ->
          :motd

        "LUSERS" ->
          :lusers

        "VERSION" ->
          :version

        "STATS" ->
          :stats

        "LINKS" ->
          :links

        "TIME" ->
          :time

        "CONNECT" ->
          :connect

        "TRACE" ->
          :trace

        "ADMIN" ->
          :admin

        "INFO" ->
          :info

        "SERVLIST" ->
          :servlist

        "WHO" ->
          :who

        "WHOIS" ->
          :whois

        "WHOWAS" ->
          :whowas

        "KILL" ->
          :kill

        "PING" ->
          :ping

        "PONG" ->
          :pong

        "ERROR" ->
          :error

        "AWAY" ->
          :away

        "REHASH" ->
          :rehash

        "DIE" ->
          :die

        "RESTART" ->
          :restart

        "SUMMON" ->
          :summon

        "USERS" ->
          :users

        "WALLOPS" ->
          :wallops

        "USERHOST" ->
          :userhost

        "ISON" ->
          :ison

        other -> other
      end

    case tail |> String.split(" :", parts: 2) do
      [head, tail] ->
        %__MODULE__{
          prefix: origin,
          command: verb,
          args_head: head |> String.split(" "),
          args_tail: tail
        }

      [head] ->
        %__MODULE__{
          prefix: origin,
          command: verb,
          args_head: head |> String.split(" "),
          args_tail: nil
        }
    end
  end

  def decode(pack) do
    unless is_nil(pack.prefix) do
      ":" <> pack.prefix <> " "
    else
      ""
    end <>
      pack.command <>
      Enum.join(pack.args_head, " ") <>
      unless is_nil(pack.args_tail) do
        ":" <> pack.args_tail
      else
        ""
      end <> "\r\n"
  end

  # ============================================================================
end
