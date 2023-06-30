defmodule TwitClone.Tweets.Comment do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias TwitClone.Accounts.User
  alias TwitClone.Tweets.Tweet

  schema "comments" do
    field :body, :string
    field :image, :string
    belongs_to :user, User
    belongs_to :tweet, Tweet

    timestamps()
  end

  @doc false
  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:body, :image, :user_id, :tweet_id])
    |> validate_required([:body, :user_id, :tweet_id])
  end
end
