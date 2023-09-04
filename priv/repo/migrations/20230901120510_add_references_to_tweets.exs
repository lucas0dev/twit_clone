defmodule TwitClone.Repo.Migrations.AddReferencesToTweets do
  use Ecto.Migration

  def change do
    alter table("tweets") do
      add :parent_tweet_id, references(:tweets, on_delete: :delete_all)
    end

    create index(:tweets, [:parent_tweet_id])
  end
end
