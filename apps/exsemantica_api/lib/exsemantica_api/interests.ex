defmodule ExsemanticaApi.Interests do
  require Logger
  use ExsemanticaApi.RateLimited
  
  @impl true
  def handle_use(_agent, state, _idx) do
    {:reply, state, :ok}
  end
   
  @impl true
  def handle_local_throttle(agent, state, idx) do
    Logger.info("Agent #{agent} with ID #{inspect(idx)} rate limited.")
    Process.sleep(1000)
    {:ok, json} = Jason.encode(%{error: true, message: "You are being rate limited."})
    {:reply, state, {:halt, {429, json}}}
  end

  @impl true
  def handle_global_throttle(agent, state, idx) do
    Logger.warn("Agent #{agent} with ID #{inspect(idx)} is inducing a global throttle!")
    Process.sleep(1000)
    {:ok, json} = Jason.encode(%{error: true, message: "The server is being rate limited."})
    {:reply, state, {:halt, {429, json}}}
  end
end
