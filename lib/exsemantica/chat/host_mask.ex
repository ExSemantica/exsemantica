defmodule Exsemantica.Chat.HostMask do
  @moduledoc """
  IRC host mask conveniences
  """
  def get(state) do
    "#{state.requested_handle}!#{state.ident}@#{state.vhost}"
  end

  def services do
    "Services!bot@bot/Services"
  end
end
