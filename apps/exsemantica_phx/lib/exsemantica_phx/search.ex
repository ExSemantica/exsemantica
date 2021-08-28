defmodule ExsemanticaPhx.Search do
  import Ecto.Query

  def interests(qstring, opts, operation \\ :count) do
    # Construct the query
    query = case Keyword.get(opts, :d0) do
      # No date bound
      nil -> {:ok, from(int in "site_posts", where: like(int.title, ^qstring) and int.is_interest, select: [int.title, int.content, int.inserted_at, int.updated_at, int.poster])}
      d0 -> case Keyword.get(opts, :d1) do
        # Why would you define a bound that's uneven
        nil -> {:error, :unsupported}

        # Date bound is fully defined, proceed
        d1 -> {:ok, from(int in "site_posts", where: like(int.title, ^qstring) and int.is_interest and int.inserted_at > ^d0 and int.inserted_at < ^d1, select: [int.title, int.content, int.inserted_at, int.updated_at])}
      end
    end

    # Use the query?
    case query do
      {:ok, q} ->
        case operation do
          :count -> ExsemanticaPhx.Repo.all(q) |> length
          :query -> ExsemanticaPhx.Repo.all(q)
        end
    end
  end


  def users(qstring, opts, operation \\ :count) do
    # Construct the query
    query = case Keyword.get(opts, :d0) do
      # No date bound
      nil -> {:ok, from(int in "site_users", where: like(int.username, ^qstring), select: [int.username, int.biography, int.inserted_at])}
      d0 -> case Keyword.get(opts, :d1) do
        # Why would you define a bound that's uneven
        nil -> {:error, :unsupported}

        # Date bound is fully defined, proceed
        d1 -> {:ok, from(int in "site_users", where: like(int.username, ^qstring) and int.inserted_at > ^d0 and int.inserted_at < ^d1, select: [int.username, int.biography, int.inserted_at])}
      end
    end

    # Use the query?
    case query do
      {:ok, q} ->
        case operation do
          :count -> ExsemanticaPhx.Repo.all(q) |> length
          :query -> ExsemanticaPhx.Repo.all(q)
        end
    end
  end

  def max_id() do
    nodes = ExsemanticaPhx.Repo.one(from post in "site_posts", select: max(post.node_corresponding))
    users = ExsemanticaPhx.Repo.one(from user in "site_users", select: max(user.node_corresponding))
    [nodes, users] |> Enum.map(fn a -> 
      case a do
        nil -> -1
        item -> item
      end
    end) |> Enum.max()
  end
end
