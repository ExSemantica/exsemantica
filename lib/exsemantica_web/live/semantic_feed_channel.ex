defmodule ExsemanticaWeb.Live.SemanticFeedChannel do
  use ExsemanticaWeb, :channel

  def join("lv_semantic_feed:home", _message, socket) do
    {:ok, socket}
  end
end
