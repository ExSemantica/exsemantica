defmodule Exsemantica.Task do
  @moduledoc """
  Asynchronous, heavy code should implement this
  """
  @callback run(args :: map()) :: {:ok, any()} | {:error, any()}
end
