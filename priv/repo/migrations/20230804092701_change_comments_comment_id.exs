defmodule TwitClone.Repo.Migrations.ChangeCommentsCommentId do
  use Ecto.Migration

  def up do
    execute "ALTER TABLE comments DROP CONSTRAINT comments_comment_id_fkey"

    alter table(:comments) do
      modify :comment_id, references(:comments, on_delete: :delete_all)
    end
  end

  def down do
    execute "ALTER TABLE comments DROP CONSTRAINT comments_comment_id_fkey"

    alter table(:comments) do
      modify :comment_id, references(:comments, on_delete: :nothing)
    end
  end
end
