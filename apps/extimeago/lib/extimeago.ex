# Copyright 2019-2020 Roland Metivier
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
defmodule ExTimeAgo do
  @moduledoc """
  Documentation for `Extimeago`.
  """

  defmodule Timespan do
    @moduledoc """
    Millisecond-precise date and timespan
    """
    @enforce_keys [:dt, :ms]
    defstruct dt: {{0, 0, 0}, {0, 0, 0}}, ms: 0

    @type t :: %__MODULE__{
            dt: {{integer, integer, integer}, {integer, integer, integer}},
            ms: integer
          }
  end

  @spec string!(Timespan.t()) :: binary
  def string!(span) do
    string(span, false)
  end

  defp determine_separator(val) when val, do: " "
  defp determine_separator(_), do: ""

  # n < 1ms
  defp string(%Timespan{dt: {{0, 1, 1}, {0, 0, 0}}, ms: 0}, false) do
    "<1ms"
  end

  # 1sec > n > 1ms (or if we bail out)
  defp string(%Timespan{dt: {{0, 1, 1}, {0, 0, 0}}, ms: 0}, true) do
    ""
  end

  defp string(%Timespan{dt: {{0, 1, 1}, {0, 0, 0}}, ms: ms}, sep) when ms > 0 and ms < 1000 do
    determine_separator(sep) <> "#{ms}ms"
  end

  # 1min > n > 1sec
  defp string(span = %Timespan{dt: {{0, 1, 1}, {0, 0, 0}}, ms: _}, _) do
    string(span, true)
  end

  defp string(span = %Timespan{dt: {{0, 1, 1}, {0, 0, dsec}}, ms: _}, sep)
       when dsec > 0 and dsec < 60 do
    determine_separator(sep) <> "#{dsec}sec" <> string(%{span | dt: {{0, 1, 1}, {0, 0, 0}}}, true)
  end

  # 1min > n > 1sec
  defp string(span = %Timespan{dt: {{0, 1, 1}, {0, 0, _}}, ms: _}, _) do
    string(%{span | dt: {{0, 1, 1}, {0, 0, 0}}}, true)
  end

  defp string(span = %Timespan{dt: {{0, 1, 1}, {0, dmin, dsec}}, ms: _}, sep)
       when dmin > 0 and dmin < 60 do
    determine_separator(sep) <>
      "#{dmin}min" <> string(%{span | dt: {{0, 1, 1}, {0, 0, dsec}}}, true)
  end

  # 1hr > n > 1min
  defp string(span = %Timespan{dt: {{0, 1, 1}, {0, _, dsec}}, ms: _}, _) do
    string(%{span | dt: {{0, 1, 1}, {0, 0, dsec}}}, true)
  end

  defp string(span = %Timespan{dt: {{0, 1, 1}, {dhr, dmin, dsec}}, ms: _}, sep)
       when dhr > 0 and dhr < 24 do
    determine_separator(sep) <>
      "#{dhr}hr" <> string(%{span | dt: {{0, 1, 1}, {0, dmin, dsec}}}, true)
  end

  # 1d > n > 1hr
  defp string(span = %Timespan{dt: {{0, 1, 1}, {_, dmin, dsec}}, ms: _}, _) do
    string(%{span | dt: {{0, 1, 1}, {0, dmin, dsec}}}, true)
  end

  defp string(span = %Timespan{dt: {{0, 1, dd}, {dhr, dmin, dsec}}, ms: _}, sep) when dd > 1 do
    determine_separator(sep) <>
      "#{dd - 1}dy" <> string(%{span | dt: {{0, 1, 1}, {dhr, dmin, dsec}}}, true)
  end

  # 1m > n > 1d
  defp string(span = %Timespan{dt: {{0, 1, dd}, {dhr, dmin, dsec}}, ms: _}, _) when dd > 1 do
    string(%{span | dt: {{0, 1, 1}, {dhr, dmin, dsec}}}, true)
  end

  defp string(span = %Timespan{dt: {{0, dm, dd}, {dhr, dmin, dsec}}, ms: _}, sep) when dm > 1 do
    determine_separator(sep) <>
      "#{dm - 1}mo" <> string(%{span | dt: {{0, 1, dd}, {dhr, dmin, dsec}}}, true)
  end

  # n > 1y
  defp string(span = %Timespan{dt: {{dy, dm, dd}, {dhr, dmin, dsec}}, ms: _}, _) when dy > 0 do
    "#{dy}yr" <> string(%{span | dt: {{0, dm, dd}, {dhr, dmin, dsec}}}, true)
  end
end
