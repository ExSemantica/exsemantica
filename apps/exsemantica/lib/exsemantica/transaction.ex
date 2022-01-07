# Copyright 2019-2022 Roland Metivier
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
defmodule Exsemantica.Transaction do
  @moduledoc """
  The ExSemantica transaction client, a `Producer`.
  """
  require Logger
  use GenStage

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(args), do: GenStage.start_link(__MODULE__, args)

  # ============================================================================
  # Callbacks
  # ============================================================================
  @impl true
  def init(queue) do
    {:producer, queue}
  end

  @impl true
  def handle_demand(demand, [head | tail]) when demand > 0 do
    {:noreply,
     [
       %{
         head
         | source: self()
       }
     ], tail}
  end
end
