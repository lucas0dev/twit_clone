defmodule TwitClone.Repo.Migrations.ChangeCommentBodyToText do
  use Ecto.Migration

  def change do
    # alter will modify the posts table
    alter table(:comments) do
      # modifies the body column from string to text
      modify :body, :text
    end
  end
end
