defmodule TwitClone.Repo.Migrations.CreateComments do
  use Ecto.Migration

  def change do
    create table(:comments) do
      add :body, :string
      add :image, :string
      add :user_id, references(:users, on_delete: :nothing)
      add :tweet_id, references(:tweets, on_delete: :nothing)

      timestamps()
    end

    create index(:comments, [:user_id])
    create index(:comments, [:tweet_id])
  end
end
