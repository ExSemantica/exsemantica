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
defmodule Exsemantica.Database.Test do
  use ExUnit.Case, async: true
  doctest Exsemantica.Database

  test "adds an object" do
    start_supervised!({Exsemantica.Database, tables: [{:test_objs, ~w(idx str)a}]})

    Exsemantica.Database.transaction([
      %{operation: :put, table: :test_objs, info: {:test_objs, 1, "Hello, world!"}},
      %{operation: :put, table: :test_objs, info: {:test_objs, 2, "Goodbye, Mars!"}}
    ])

    {:atomic, [response]} =
      Exsemantica.Database.transaction([
        %{operation: :get, table: :test_objs, info: 2}
      ])

    assert [{:test_objs, 2, "Goodbye, Mars!"}] == response.response
  end
end
