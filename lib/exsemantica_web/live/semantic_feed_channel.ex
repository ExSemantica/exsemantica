defmodule ExsemanticaWeb.Live.SemanticFeedChannel do
  use ExsemanticaWeb, :channel

  def join("lv_semantic_feed:home", _message, socket) do
    {:ok, socket}
  end

  def handle_in("lv_semantic_feed:home",%{type: :user, }, _socket) do

  end
end
