defmodule TwitClone.Repo.Migrations.AddCommentIdToCommentsTable do
  use Ecto.Migration

  def change do
    alter table("comments") do
      add :comment_id, references(:comments, on_delete: :nothing)
    end

    create index(:comments, [:comment_id])
  end
end
