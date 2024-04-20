defmodule Exsemantica.API do
  @moduledoc """
  Application Programming Interface root route
  """
  import Exsemantica.Gettext

  @errors_json %{
    bad_request:
      Jason.encode!(%{
        e: "BAD_REQUEST",
        message: gettext("Invalid data or other bad request.")
      }),
    bad_data_type:
      Jason.encode!(%{
        e: "BAD_DATA_TYPE",
        message: gettext("Bad content type.")
      }),
    internal_server_error:
      Jason.encode!(%{
        e: "INTERNAL_SERVER_ERROR",
        message: gettext("Something went wrong.")
      }),
    endpoint_not_found:
      Jason.encode!(%{
        e: "ENDPOINT_NOT_FOUND",
        message: gettext("That endpoint currently does not exist.")
      })
  }

  use Plug.Router
  use Plug.ErrorHandler

  plug(Plug.Parsers,
    parsers: [:urlencoded, {:json, json_decoder: Jason}]
  )

  plug(:match)
  plug(:dispatch)

  get("/.well-known/exsemantica/application",
    do: conn |> __MODULE__.WellKnown.Application.call([])
  )

  post("/authentication/log_in", do: conn |> __MODULE__.Authentication.LogIn.call([]))
  post("/authentication/refresh", do: conn |> __MODULE__.Authentication.Refresh.call([]))
  post("/authentication/register", do: conn |> __MODULE__.Authentication.Register.call([]))

  match _ do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(
      404,
      @errors_json.endpoint_not_found
    )
  end

  @impl Plug.ErrorHandler
  def handle_errors(conn, %{kind: :error, reason: %{plug_status: 400}, stack: _stack}) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(
      400,
      @errors_json.bad_request
    )
  end

  @impl Plug.ErrorHandler
  def handle_errors(conn, %{kind: :error, reason: %{plug_status: 415}, stack: _stack}) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(
      415,
      @errors_json.bad_data_type
    )
  end

  @impl Plug.ErrorHandler
  def handle_errors(conn, %{kind: _kind, reason: _reason, stack: _stack} = args) do
    IO.inspect(args)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(
      500,
      @errors_json.internal_server_error
    )
  end
end
