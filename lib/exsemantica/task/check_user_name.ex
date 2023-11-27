defmodule Exsemantica.Task.CheckUserName do
  @moduledoc """
  A task that transforms the name of a user
  """
  @behaviour Exsemantica.Task
  import Ecto.Query

  @impl true
  def run(%{guess: guess}) do
    data =
      Exsemantica.Repo.one(
        from u in Exsemantica.Repo.User,
          where: ilike(u.username, ^guess),
          select: u
      )

    case data do
      nil ->
        :not_found

      user ->
        %{id: user.id, name: user.username, identical?: user.username == guess}
    end
  end
end
