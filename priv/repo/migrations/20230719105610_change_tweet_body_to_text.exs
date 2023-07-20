defmodule TwitClone.Repo.Migrations.ChangeTweetBodyToText do
  use Ecto.Migration

  def change do
    # alter will modify the posts table
    alter table(:tweets) do
      # modifies the body column from string to text
      modify :body, :text
    end
  end
end
