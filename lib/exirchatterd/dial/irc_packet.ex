defmodule Exirchatterd.IRCPacket do
  @moduledoc """
  Define the IRC packet structure per RFC2812
  """
  defstruct prefix: nil, root: nil, postfix: nil
  @type t :: %__MODULE__{prefix: binary(), root: binary(), postfix: binary()}

  def structure(raw) do
    {prefix, root, postfix} = if raw |> String.starts_with?(":") do
      [raw_prefix, root, raw_postfix] = raw |> String.split(" ", parts: 3)
      prefix = String.trim_leading(raw_prefix, ":")
      postfix = String.trim_leading(raw_postfix, ":")
      {prefix, root, postfix}
    else
      [root, raw_postfix] = raw |> String.split(" ", parts: 2)
      postfix = String.trim_leading(raw_postfix, ":")
      {nil, root, postfix}
    end
    %__MODULE__{
      prefix: prefix,
      root: root,
      postfix: postfix
    }
  end

  def stringify(st) do

  end
end
