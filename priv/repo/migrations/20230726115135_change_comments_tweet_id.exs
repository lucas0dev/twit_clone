defmodule TwitClone.Repo.Migrations.ChangeCommentsTweetId do
  use Ecto.Migration

  def up do
    execute "ALTER TABLE comments DROP CONSTRAINT comments_tweet_id_fkey"

    alter table(:comments) do
      modify :tweet_id, references(:tweets, on_delete: :delete_all)
    end
  end

  def down do
    execute "ALTER TABLE comments DROP CONSTRAINT comments_tweet_id_fkey"

    alter table(:comments) do
      modify :tweet_id, references(:tweets, on_delete: :nothing)
    end
  end
end
