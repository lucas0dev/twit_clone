defmodule TwitClone.Tweets.Tweet do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias TwitClone.Accounts.User

  schema "tweets" do
    field :body, :string
    field :image, :string
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(tweet, attrs) do
    tweet
    |> cast(attrs, [:body, :user_id, :image])
    |> validate_required([:body, :user_id])
    |> validate_length(:body, max: 280)
  end
end
