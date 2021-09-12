defmodule ExsemanticaApiTest do
  use ExUnit.Case
  doctest ExsemanticaApi

  test "greets the world" do
    assert ExsemanticaApi.hello() == :world
  end
end
