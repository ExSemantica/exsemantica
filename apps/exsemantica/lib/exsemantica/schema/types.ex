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
defmodule Exsemantica.Schema.Types do
  use Absinthe.Schema.Notation

  scalar :id128 do
    description("Unique Identifier (128-bit base64 machine-readable value)")
    parse(&Exsemantica.Id128.parse/1)
    serialize(&Exsemantica.Id128.serialize/1)
  end

  scalar :handle128 do
    description("Handle (16-char string value)")
    parse(&Exsemantica.Handle128.parse/1)
    serialize(&Exsemantica.Handle128.serialize/1)
  end
  # ============================================================================
  # User data
  # ============================================================================
  object :user do
    field :node, :id128
    field :handle, :handle128
  end
  # ============================================================================
  # Post data
  # ============================================================================
  object :post do
    field :node, :id128
    field :title, :string
    field :content, :string
    field :posted_by, :id128
  end
  # ============================================================================
  # Interest data
  # ============================================================================
  object :interest do
    field :node, :id128
    field :title, :string
    field :content, :string
    field :related_to, list_of(:id128)
  end
end
