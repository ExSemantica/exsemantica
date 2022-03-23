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
    invite = :persistent_term.get(:exseminvite)
    invite_match = conn.body_params["invite"]

    case Exsemnesia.Utils.login_user(conn.body_params["user"], conn.body_params["pass"]) do
      {:ok, login_user} when invite === invite_match ->
        {:ok, json} =
          Jason.encode(%{
            success: true,
            # The handle of the user.
            handle: login_user.handle
          })

        conn |> put_session(:login_paseto, login_user.paseto) |> send_resp(200, json)

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
    invite_incoming = conn.body_params["invite"]
    invite_outgoing = Base.url_encode64(:persistent_term.get(:exseminvite))
    no_registration = not prefs.registration_enabled

    cond do
      no_registration ->
        {:ok, json} =
          Jason.encode(%{
            success: false,
            error_code: "E_NO_REGISTRATIONS",
            description: "Registration is disabled on this instance."
          })

        conn |> send_resp(401, json)

      invite_incoming != invite_outgoing -> {:ok, json} =
        Jason.encode(%{
          success: false,
          error_code: "E_INVITE_INVALID",
          description: "The invite code has already been used."
        })
        conn |> send_resp(400, json)

      invite_incoming == invite_outgoing ->
        handle = Exsemnesia.Handle128.serialize(conn.body_params["user"])
        result = Exsemnesia.Utils.create_user(handle, conn.body_params["pass"])

        case result do
          {:error, :eusers} ->
            {:ok, json} =
              Jason.encode(%{
                success: false,
                error_code: "E_USER_EXISTS",
                description: "The user already exists."
              })
              conn |> send_resp(400, json)
          {:error, :einval} ->
            {:ok, json} =
              Jason.encode(%{
                success: false,
                error_code: "E_INVALID_USERNAME",
                description: "The username is invalid."
              })

            conn |> send_resp(400, json)

          {:ok, handle} ->
            {:ok, json} =
              Jason.encode(%{
                success: true,
                # The handle of the user.
                handle: handle
              })

            conn |> send_resp(200, json)
        end
    end
  end
end
