defmodule TwitClone.Repo.Migrations.DropCommentsTable do
  use Ecto.Migration

  def change do
    drop table("comments")
  end
end
