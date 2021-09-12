defmodule ExsemanticaApi.Unimplemented do
  require Logger
  use ExsemanticaApi.RateLimited
  
  @impl true
  def handle_use(_agent, state, _idx) do
    {:ok, json} = Jason.encode(%{error: true, message: "This endpoint is unimplemented. Contact your ExSemantica instance's system administrator."})
    {:reply, state, {:ok, {501, json}}}
  end
   
  @impl true
  def handle_local_throttle(_agent, state, _idx) do
    {:ok, json} = Jason.encode(%{error: true, message: "You are being rate limited."})
    {:reply, state, {:rate_limited, {429, json}}}
  end

  @impl true
  def handle_global_throttle(_agent, state, _idx) do
    {:ok, json} = Jason.encode(%{error: true, message: "The server is being rate limited."})
    {:reply, state, {:rate_limited, {429, json}}}
  end
end
