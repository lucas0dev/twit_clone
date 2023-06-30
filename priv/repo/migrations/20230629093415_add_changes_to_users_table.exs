defmodule TwitClone.Repo.Migrations.AddChangesToUsersTable do
  use Ecto.Migration

  def change do
    alter table("users") do
      add :account_name, :string
      add :name, :string
      add :avatar, :string
    end

    create(
      unique_index(
        :users,
        :account_name,
        name: :index_for_unique_name
      )
    )
  end
end
