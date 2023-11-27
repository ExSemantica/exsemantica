defmodule Exsemantica.Task.LoadAggregatePage do
  @moduledoc """
  A task that loads an aggregate page's data
  """
  @max_posts_per_page 10
  @behaviour Exsemantica.Task
  import Ecto.Query

  @impl true
  def run(%{id: id, load_by: load_by, page: page}) do
    data =
      Exsemantica.Repo.one(Exsemantica.Repo.Aggregate, id: id)

    case data do
      # Couldn't find the aggregate
      nil ->
        :not_found

      # Only load the name and description if the page is nil
      # TODO: Load other statistics?
      aggregate when is_nil(page) ->
        %{aggregate: aggregate}

      # Load a page from the aggregate
      aggregate ->
        %{aggregate: aggregate, page_info: aggregate.id |> fetch_posts(load_by, page)}
    end
  end

  defp fetch_posts(id, :newest, page) do
    all_count =
      Exsemantica.Repo.aggregate(
        from(p in Exsemantica.Repo.Post, where: p.aggregate_id == ^id),
        :count
      )

    pages_total = div(all_count, @max_posts_per_page)
    offset = all_count - page * @max_posts_per_page

    %{
      contents:
        if pages_total > page do
          Exsemantica.Repo.all(
            from a in Exsemantica.Repo.Aggregate,
              where: a.id == ^id,
              preload: [posts: [order_by: [desc: :inserted_at]]]
          )
          |> Enum.slice(offset, @max_posts_per_page)
        else
          []
        end,
      pages_total: pages_total,
      pages_began?: page < 1,
      pages_ended?: page > pages_total - 1
    }
  end
end
