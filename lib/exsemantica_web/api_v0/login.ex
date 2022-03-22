defmodule ExsemanticaWeb.APIv0.Login do
  use ExsemanticaWeb, :controller

  require Exsemnesia.Handle128

  def get_attributes(conn, _opts) do
    conn = conn |> fetch_query_params()

    case conn.query_params do
      %{"user" => user} ->
        handle = Exsemnesia.Handle128.serialize(user)

        case handle do
          :error ->
            {:ok, json} =
              Jason.encode(%{
                success: false,
                error_code: "E_INVALID_USERNAME",
                description: "The username is invalid."
              })

            conn |> send_resp(400, json)

          transliterated ->
            {:ok, json} =
              Jason.encode(%{
                success: true,
                parsed: transliterated,
                unique: Exsemnesia.Utils.unique?(transliterated)
              })

            conn |> send_resp(200, json)
        end

      _ ->
        {:ok, json} =
          Jason.encode(%{
            success: false,
            error_code: "E_NO_USERNAME",
            description: "The username has to be specified."
          })

        conn |> send_resp(400, json)
    end
  end

  def post_authentication(conn, _opts) do
    case Exsemnesia.Utils.login_user(conn.body_params["user"], conn.body_params["pass"]) do
      {:ok, login_user} ->
        {:ok, json} =
          Jason.encode(%{
            success: true,
            # The handle of the user.
            handle: login_user.handle,
            # Meant to be saved as a cookie to log in
            paseto: login_user.paseto
          })

        conn |> send_resp(200, json)

      {:error, :einval} ->
        {:ok, json} =
          Jason.encode(%{
            success: false,
            error_code: "E_INVALID_USERNAME",
            description: "The username is invalid."
          })

        conn |> send_resp(400, json)

      {:error, :eacces} ->
        {:ok, json} =
          Jason.encode(%{
            success: false,
            error_code: "E_ACCESS_DENIED",
            description: "Authentication failed."
          })

        conn |> send_resp(400, json)

      {:error, :enoent} ->
        {:ok, json} =
          Jason.encode(%{
            success: false,
            error_code: "E_NO_USERNAME",
            description: "The username has to be specified."
          })

        conn |> send_resp(400, json)
    end
  end

  def put_registration(conn, _opts) do
    prefs = :persistent_term.get(:exsemprefs)

    if prefs.registration_enabled do
      case Exsemnesia.Utils.create_user(
             conn.body_params["user"],
             conn.body_params["pass"]
           ) do
        {:ok, created_user} ->
          {:ok, json} =
            Jason.encode(%{
              success: true,
              # The handle of the user.
              handle: created_user.handle
            })

          conn |> send_resp(200, json)

        {:error, :einval} ->
          {:ok, json} =
            Jason.encode(%{
              success: false,
              error_code: "E_INVALID_USERNAME",
              description: "The username is invalid."
            })

          conn |> send_resp(400, json)

        {:error, :eusers} ->
          {:ok, json} =
            Jason.encode(%{
              success: false,
              error_code: "E_USER_EXISTS",
              description: "The user already exists."
            })

          conn |> send_resp(400, json)
      end
    else
      {:ok, json} =
        Jason.encode(%{
          success: false,
          error_code: "E_NO_REGISTRATIONS",
          description: "Registration is disabled on this instance."
        })

      conn |> send_resp(401, json)
    end
  end
end
