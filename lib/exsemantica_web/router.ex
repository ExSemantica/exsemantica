defmodule ExsemanticaWeb.Router do
  use ExsemanticaWeb, :router

  pipeline :browser do
    plug Guardian.Plug.Pipeline,
      module: Exsemantica.Auth.Guardian

    plug :accepts, ["html"]
    plug :fetch_session
    plug Guardian.Plug.VerifySession, claims: %{"typ" => "access"}, key: :token
    plug Guardian.Plug.LoadResource, allow_blank: true
    plug :fetch_live_flash
    plug :put_root_layout, html: {ExsemanticaWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ExsemanticaWeb do
    pipe_through :browser

    live_session :main do
      live "/", MainLive, :redirect_to_all
      live "/s/:aggregate", MainLive, :aggregate
      live "/u/:username", MainLive, :user
    end
  end

  scope "/api/", ExsemanticaWeb do
    pipe_through :api

    post "/login", API.Auth, :log_in
    # post "/register", API.Auth, :register
    post "/logout", API.Auth, :log_out
  end

  # Other scopes may use custom stacks.
  # scope "/api", ExsemanticaWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:exsemantica, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: ExsemanticaWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
