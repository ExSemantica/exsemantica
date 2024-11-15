defmodule Exsemantica.Administration.Chat do
  @moduledoc """
  Conveniences for administering the chat server
  """

  @doc """
  Terminates a client's IRC connection from Services.

  The handle is case-sensitive.
  """
  def kill_client(handle, reason \\ "No reason") do
    user = Registry.lookup(Exsemantica.Chat.UserRegistry, handle)

    case user do
      [{pid, _}] -> pid |> Exsemantica.Chat.User.kill_connection("Services", reason)
      [] -> {:error, :not_found}
    end
  end

  @doc """
  Sends a WALLOPS notice from Services to all clients with +w user mode.
  """
  def wallops(what) do
    Exsemantica.Chat.UserSupervisor.broadcast_wallops(what)
  end
end
