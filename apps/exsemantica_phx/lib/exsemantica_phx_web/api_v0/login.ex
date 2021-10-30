defmodule ExsemanticaPhxWeb.ApiV0.Login do
  import Plug.Conn

  @spec init(any) :: any
  def init(opts) do
    opts
  end

  @spec call(Plug.Conn.t(), any) :: Plug.Conn.t()
  def call(conn, _opts) do
    uquery = get_in(conn.query_params, ["user"]) || ""
    valid = ExsemanticaPhx.Sanitize.valid_username?(uquery)

    {status, response} =
      if valid do
        unverified = uquery |> ExsemanticaPhx.Protect.find_contract() |> is_nil

        if unverified do
          {:ok, json} =
            Jason.encode(%{e: true, msg: "This user has not verified their registration."})

          {200, json}
        end
      else
        {:ok, whoops} =
          Jason.encode(%{
            e: true,
            msg: "The username you are trying to log into is invalid."
          })

        {400, whoops}
      end

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, response)
  end
end
