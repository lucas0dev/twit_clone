defmodule TwitClone.Tweets.Comment do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias TwitClone.Accounts.User
  alias TwitClone.Tweets.Comment
  alias TwitClone.Tweets.Tweet

  schema "comments" do
    field :body, :string
    field :image, :string
    belongs_to :user, User
    belongs_to :tweet, Tweet
    belongs_to :comment, Comment
    has_many :replies, Comment, foreign_key: :comment_id
    timestamps()
  end

  @doc false
  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:body, :image, :user_id, :tweet_id, :comment_id])
    |> validate_required([:user_id, :tweet_id])
    |> validate_image_and_body()
    |> validate_length(:body, max: 280)
  end

  def validate_image_and_body(changeset) do
    with nil <- get_field(changeset, :body),
         nil <- get_field(changeset, :image) do
      add_error(changeset, :body, "image and comment content can't be blank at the same time")
    else
      _ -> changeset
    end
  end
end
