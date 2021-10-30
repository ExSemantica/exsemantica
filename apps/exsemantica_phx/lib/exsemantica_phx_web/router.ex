defmodule ExsemanticaPhxWeb.Router do
  use ExsemanticaPhxWeb, :router

  import Plug.Conn

  # ============================================================================
  # HTML and JSON rate limit hit endpoints
  # ============================================================================
  @spec html_rate_429(Plug.Conn.t(), any) :: Task.t()
  @doc """
  Asynchronously constructs the HTTP 429 response for an HTML client.

  This must be awaited. The task in turn returns an `{:ok, conn}` tuple.
  """
  def html_rate_429(conn, s) do
    conn = conn |> send_chunked(429)

    Task.async(fn ->
      Process.sleep(1000)
      conn |> chunk("429 Rate Limited\r\n\r\nYou are being rate limited. Wait #{s} seconds to refresh the page.\r\n")
    end)
  end

  @spec html_rate_403(Plug.Conn.t()) :: Task.t()
  @doc """
  Asynchronously constructs the HTTP 403 response for an HTML client.

  This must be awaited. The task in turn returns an `{:ok, conn}` tuple.
  """
  def html_rate_403(conn) do
    conn = conn |> send_chunked(403)

    Task.async(fn ->
      Process.sleep(1000)
      conn |> chunk("403 Forbidden\r\n\r\nYou are not allowed this site.\r\n")
    end)
  end

  @spec json_rate_429(Plug.Conn.t(), any) :: Task.t()
  @doc """
  Asynchronously constructs the HTTP 429 response for an API client.

  This must be awaited. The task in turn returns an `{:ok, conn}` tuple.
  """
  def json_rate_429(conn, s) do
    {:ok, json} =
      Jason.encode(%{e: true, msg: "You are being rate limited. Wait #{s} seconds to try again."})

    conn = conn |> send_chunked(429)

    Task.async(fn ->
      Process.sleep(1000)
      conn |> chunk(json)
    end)
  end

  @spec json_rate_403(Plug.Conn.t()) :: Task.t()
  @doc """
  Asynchronously constructs the HTTP 403 response for an API client.

  This must be awaited. The task in turn returns an `{:ok, conn}` tuple.
  """
  def json_rate_403(conn) do
    {:ok, json} = Jason.encode(%{e: true, msg: "You are not allowed to use this endpoint."})

    conn = conn |> send_chunked(403)

    Task.async(fn ->
      Process.sleep(1000)
      conn |> chunk(json)
    end)
  end

  # ============================================================================
  # Pipelines
  # ============================================================================
  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {ExsemanticaPhxWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers

    plug(
      ExsemanticaApi.RateLimited,
      requested_limit: 2,
      interval: 1,
      on_limit: &__MODULE__.html_rate_429/2,
      on_forbidden: &__MODULE__.html_rate_403/1
    )
  end

  pipeline :api_slow do
    plug(
      ExsemanticaApi.RateLimited,
      requested_limit: 2,
      interval: 1,
      on_limit: &__MODULE__.json_rate_429/2,
      on_forbidden: &__MODULE__.json_rate_403/1
    )

    plug :accepts, ["json"]
  end

  pipeline :api_fast do
    plug(
      ExsemanticaApi.RateLimited,
      requested_limit: 5,
      interval: 1,
      on_limit: &__MODULE__.json_rate_429/2,
      on_forbidden: &__MODULE__.json_rate_403/1
    )

    plug :accepts, ["json"]
  end

  # ============================================================================
  # Scopes
  # ============================================================================
  scope "/", ExsemanticaPhxWeb do
    pipe_through :browser

    live "/", PageLive, :index
  end

  scope "/api" do
    pipe_through :api_fast

    forward "/v0/interests", ExsemanticaPhxWeb.ApiV0.Interests
    forward "/v0/users", ExsemanticaPhxWeb.ApiV0.Users
  end

  scope "/api" do
    pipe_through :api_slow

    forward "/v0/login", ExsemanticaPhxWeb.ApiV0.Login
  end

  # ============================================================================
  # LiveDashboard
  # ============================================================================
  # Other scopes may use custom stacks.
  # scope "/api", ExsemanticaPhxWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser

      live_dashboard "/dashboard",
        metrics: ExsemanticaPhxWeb.Telemetry,
        ecto_repos: [ExsemanticaPhx.Repo]
    end
  end
end
