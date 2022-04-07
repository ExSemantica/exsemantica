defmodule ExsemanticaWeb.APIv0.Wants do
  use ExsemanticaWeb, :controller

  require Exsemnesia.Handle128

  def get_enabled(conn, _opts) do
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
end
