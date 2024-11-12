defmodule Exsemantica.Administration.Chat do
  @moduledoc """
  Conveniences for administering the chat server
  """

  @doc """
  Terminates a client's IRC connection. The handle is case-sensitive.
  """
  def kill_client(handle, reason \\ "No reason") do
    user = Registry.lookup(Exsemantica.Chat.UserRegistry, handle)

    case user do
      [{pid, _}] -> pid |> Exsemantica.Chat.User.kill_connection("Services", reason)
      [] -> {:error, :not_found}
    end
  end
end
