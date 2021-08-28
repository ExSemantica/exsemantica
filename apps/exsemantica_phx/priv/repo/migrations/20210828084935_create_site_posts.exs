defmodule ExsemanticaPhx.Repo.Migrations.CreateSitePosts do
  use Ecto.Migration

  def change do
    create table(:site_posts) do
      add :node_corresponding, :integer
      add :title, :text
      add :content, :text
      add :is_interest, :boolean, default: false, null: false
      add :poster, :integer

      timestamps()
    end

    create unique_index(:site_posts, [:node_corresponding])
  end
end
