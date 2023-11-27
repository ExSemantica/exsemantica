defmodule Exsemantica.Task.LoadUserPage do
  @moduledoc """
  A task that loads a user page's data
  """
  @max_posts_per_page 10
  @behaviour Exsemantica.Task
  import Ecto.Query

  @impl true
  def run(%{id: id, load_by: load_by, page: page}) do
    data =
      Exsemantica.Repo.one(Exsemantica.Repo.User, id: id)

    case data do
      # Couldn't find the user
      nil ->
        :not_found

      # Only load the name and description if the page is nil
      # TODO: Load other statistics?
      user when is_nil(page) ->
        %{user: user}

      # Load a page from the user
      user ->
        %{user: user, page_info: user.id |> fetch_posts(load_by, page)}
    end
  end

  defp fetch_posts(id, :newest, page) do
    all_count =
      Exsemantica.Repo.aggregate(
        from(p in Exsemantica.Repo.Post, where: p.user_id == ^id),
        :count
      )

    pages_total = div(all_count, @max_posts_per_page)
    offset = all_count - page * @max_posts_per_page

    %{
      contents:
        if pages_total > page do
          Exsemantica.Repo.all(
            from u in Exsemantica.Repo.User,
              where: u.id == ^id,
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
