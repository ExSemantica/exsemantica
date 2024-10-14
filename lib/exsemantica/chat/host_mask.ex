defmodule Exsemantica.Chat.HostMask do
  @moduledoc """
  IRC host mask conveniences
  """
  def get(state) do
    "#{state.handle}!#{state.user_id}@#{state.vhost}"
  end
end
