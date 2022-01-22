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
defmodule Exsemtheme.ThemingAgent do
  @moduledoc """
  Applies the actual HTML theme.
  """
  require EEx
  use Agent

  @valid_modes ~w(frontpage)a

  # ============================================================================
  # Callbacks
  # ============================================================================
  @spec start_link([{:theme, any}, ...]) :: {:error, any} | {:ok, pid}
  @doc """
  Starts the Theming Agent with the specified theme
  """
  def start_link(theme: theme) do
    Agent.start_link(
      fn ->
        @valid_modes
        |> Map.new(fn mode ->
          {mode,
           EEx.compile_file(
             Path.join([
               Application.fetch_env!(:exsemtheme, :cd),
               "templates",
               "#{theme}-#{mode}.html.eex"
             ])
           )}
        end)
      end,
      name: __MODULE__
    )
  end

  @spec apply(atom, any) :: any
  @doc """
  Applies the given mappings.

  Please make sure you strip all HTML tags.
  """
  def apply(mode, mappings) do
    Agent.get(__MODULE__, fn state ->
      {result, _bindings} = Code.eval_quoted(state[mode], mappings)
      result
    end)
  end
end
