defmodule TwitClone.Repo.Migrations.CreateRelationshipsTable do
  use Ecto.Migration

  def change do
    create table(:relationships) do
      add :followed_id, references(:users)
      add :follower_id, references(:users)
      timestamps()
    end

    create index(:relationships, [:followed_id])
    create index(:relationships, [:follower_id])

    create unique_index(
             :relationships,
             [:followed_id, :follower_id],
             name: :relationships_followed_id_follower_id_index
           )

    create unique_index(
             :relationships,
             [:follower_id, :followed_id],
             name: :relationships_follower_id_followed_id_index
           )
  end
end
