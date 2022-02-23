defmodule ExsemanticaWeb.AnnounceServer do
  use GenServer
  require Logger

  @all_announces %{
    broadcast_trends: 10000
  }
  @max_trend_entries 5

  def start_link([]), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  @impl true
  def init([]) do
    Logger.info("init announcer with #{map_size(@all_announces)} topics")
    @all_announces |> Enum.map(fn {k, v} -> Process.send_after(self(), k, v) end)
    {:ok, []}
  end

  @impl true
  def handle_info(:broadcast_trends, state) do
    Logger.debug("announcer topic: broadcast trends")
    Process.send_after(self(), :broadcast_trends, @all_announces.broadcast_trends)

    {:ok, trends} =
      """
      query GetTrends($cnt: Int, $fuzz: String) {
        trending(count: $cnt, fuzzy: $fuzz) {
          type, handle
        }
      }
      """
      |> Absinthe.run(ExsemanticaWeb.Schema,
        variables: %{
          "cnt" => @max_trend_entries,
          "fuzz" => nil
        }
      )

    :ok =
      ExsemanticaWeb.Endpoint.broadcast(
        "lv_semantic_feed:home",
        "update_trends",
        %{
          "result" => get_in(trends, [:data, "trending"]),
          "time" => DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()
        }
      )

    {:noreply, state}
  end
end
