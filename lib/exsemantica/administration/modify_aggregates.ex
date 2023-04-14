defmodule Exsemantica.Administration.ModifyAggregates do
  @moduledoc """
  Administation utilities to modify the aggregates database
  """
  require Logger

  @doc """
  Creates an aggregate
  """
  def new(name, description) do
    case Exsemantica.AggHandle.convert_to(name) do
      {:ok, handle} ->
        Logger.info("Registering new aggregate '#{handle}'")

        Exsemantica.Repo.insert(%Exsemantica.Aggregate{
          name: handle,
          description: description
        })

      :error ->
        Logger.error("Could not convert new aggregate name into an AggHandle")
    end
  end

  @doc """
  Posts to the specifed aggregate with the specified author
  """
  def post(type, aggregate_id, user_id, title, contents) do
    Exsemantica.Repo.insert(%Exsemantica.Post{
      aggregate_id: aggregate_id,
      user_id: user_id,
      type: type,
      title: title,
      contents: contents
    })
  end

  # TODO: Check if this actually works.
  def moderators_add(aggregate_id, new_moderators) do
    old_moderators = Exsemantica.Repo.get(Exsemantica.Aggregate, aggregate_id)
    |> Exsemantica.Repo.preload(:moderators)

    old_moderators |> Ecto.Changeset.change(moderators: [new_moderators | old_moderators])
    |> Exsemantica.Repo.update()
  end
end
