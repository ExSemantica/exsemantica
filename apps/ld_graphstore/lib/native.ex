defmodule LdGraphstore.Native do
  use Rustler, otp_app: :ld_graphstore, crate: :ld_graphstore
  @moduledoc """
  Native Rust NIFs to speed up left-child right-sibling tree handling.
  """

  def db_create(), do: :erlang.nif_error(:nif_not_loaded)
  def db_test(_stress), do: :erlang.nif_error(:nif_not_loaded)
end
