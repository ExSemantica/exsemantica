defmodule Exsemantica.API do
  @moduledoc """
  Application Programming Interface root route
  """
  @errors_json %{
    bad_request:
      :json.encode(%{
        e: "BAD_REQUEST"
      }),
    bad_data_type:
      :json.encode(%{
        e: "BAD_DATA_TYPE"
      }),
    internal_server_error:
      :json.encode(%{
        e: "INTERNAL_SERVER_ERROR"
      }),
    endpoint_not_found:
      :json.encode(%{
        e: "ENDPOINT_NOT_FOUND"
      })
  }

  use Plug.Router
  use Plug.ErrorHandler

  plug(Plug.Parsers,
    parsers: [:urlencoded, {:json, json_decoder: {:json, :decode, []}}]
  )

  plug(:match)
  plug(:dispatch)

  get("/.well-known/exsemantica/application",
    do: conn |> __MODULE__.WellKnown.Application.call([])
  )

  post("/authentication/log_in", do: conn |> __MODULE__.Authentication.LogIn.call([]))
  post("/authentication/refresh", do: conn |> __MODULE__.Authentication.Refresh.call([]))
  post("/authentication/register", do: conn |> __MODULE__.Authentication.Register.call([]))

  get("/gateway/aggregate/:aggregate",
    do: conn |> __MODULE__.Gateway.call(type: :aggregate, target: aggregate)
  )

  get("/gateway/user/:user", do: conn |> __MODULE__.Gateway.call(type: :user, target: user))

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
