defmodule Exsemantica.API.ErrorHandler do
  @moduledoc """
  Boilerplate error handling
  """
  import Exsemantica.Gettext

  use Plug.Builder

  def init(opts) do
    opts
  end

  def call(conn, opts) do
    case opts.message do
      :endpoint_not_found ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          404,
          Jason.encode!(%{
            e: "ENDPOINT_NOT_FOUND",
            message: gettext("That endpoint currently does not exist.")
          })
        )
    end
  end
end
