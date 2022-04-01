defmodule Exirchatterd.IRCPacket do
  @moduledoc """
  Define the IRC packet structure per RFC2812
  """
  defstruct prefix: nil, root: nil, stem: nil, postfix: nil
  @type t :: %__MODULE__{prefix: binary(), root: binary(), stem: binary(), postfix: binary()}

  @spec structure(binary) :: Exirchatterd.IRCPacket.t()
  def structure(raw) do
    {prefix, root, stem, postfix} =
      if raw |> String.starts_with?(":") do
        case raw |> String.split(" ", parts: 4) do
          [raw_prefix, root, stem, raw_postfix] ->
            prefix = String.trim_leading(raw_prefix, ":")
            postfix = String.trim_leading(raw_postfix, ":")
            {prefix, root, stem, postfix}

          [raw_prefix, root, stem] ->
            prefix = String.trim_leading(raw_prefix, ":")
            {prefix, root, stem, nil}

          [raw_prefix, root] ->
            prefix = String.trim_leading(raw_prefix, ":")
            {prefix, root, nil, nil}
        end
      else
        case raw |> String.split(" ", parts: 3) do
          [root, stem, raw_postfix] ->
            postfix = String.trim_leading(raw_postfix, ":")
            {nil, root, stem, postfix}

          [root, stem] ->
            {nil, root, stem, nil}

          [root] ->
            {nil, root, nil, nil}
        end
      end

    %__MODULE__{
      prefix: prefix,
      root: root,
      stem: stem,
      postfix: postfix
    }
  end

  def stringify(st) do
    if st.postfix do
      Enum.join([st.prefix, st.root, st.stem, ":"<>st.postfix], " ") <> "\r\n"
    else
      Enum.join([st.prefix, st.root, st.stem], " ") <> "\r\n"
    end
  end
end
