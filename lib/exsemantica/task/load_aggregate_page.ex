defmodule Exsemantica.Task.LoadAggregatePage do
  @moduledoc """
  A task that loads an aggregate page's data
  """
  @fetches ~w(posts)a
  @max_posts_per_page 5
  @behaviour Exsemantica.Task
  import Ecto.Query

  @impl true
  def run(%{id: id, fetch?: wanted_fetches} = args) do
    data = Exsemantica.Repo.get(Exsemantica.Repo.Aggregate, id)

    case data do
      # Couldn't find the aggregate
      nil ->
        :not_found

      # Load a page from the aggregate
      aggregate ->
        %{
          aggregate: aggregate,
          info:
            @fetches
            |> Enum.filter(fn match ->
              match in wanted_fetches
            end)
            |> Enum.map(fn fmatch -> fetch(fmatch, id, args) end)
            |> Map.new()
        }
    end
  end

  defp fetch(:posts, id, %{load_by: :newest, page: page, options: %{preloads: preloads}}) do
    all_count =
      Exsemantica.Repo.aggregate(
        from(p in Exsemantica.Repo.Post, where: p.aggregate_id == ^id),
        :count
      )

    pages_total = div(all_count, @max_posts_per_page)
    offset  = page * @max_posts_per_page

    posts =
      if pages_total >= page do
        aggregate =
          Exsemantica.Repo.preload(
            %Exsemantica.Repo.Aggregate{id: id},
            posts:
              from(p in Exsemantica.Repo.Post,
                order_by: [desc: p.inserted_at],
                preload: ^[:user, :aggregate | preloads]
              )
          )

        aggregate.posts
        |> Enum.slice(offset, @max_posts_per_page)
      else
        []
      end

    {:posts,
     Map.merge(
       %{
         contents: posts,
         pages_total: pages_total,
         pages_began?: page < 1,
         pages_ended?: page > pages_total - 1
       },
       if :votes in preloads do
         %{
           votes:
             posts
             |> Enum.map(fn post ->
               {post.id,
                post
                |> Map.get(:votes)
                |> Enum.reduce(
                  0,
                  fn vote, count ->
                    if vote.is_downvote, do: count - 1, else: count + 1
                  end
                )}
             end)
             |> Map.new()
         }
       else
         %{}
       end
     )}
  end
end
