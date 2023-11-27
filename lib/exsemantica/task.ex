defmodule Exsemantica.Task do
  @moduledoc """
  Asynchronous, heavy code should implement this
  """
  @callback run(args :: map()) :: map() | atom()
end
