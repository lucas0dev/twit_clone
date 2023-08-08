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

    has_many :replies, Comment,
      foreign_key: :comment_id,
      on_delete: :delete_all,
      preload_order: [desc: :id]

    timestamps()
  end

  @doc false
  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:body, :image, :user_id, :tweet_id, :comment_id])
    |> validate_required([:user_id])
    |> validate_image_and_body()
    |> validate_tweet_and_comment()
    |> validate_length(:body, max: 280)
  end

  defp validate_image_and_body(changeset) do
    with nil <- get_field(changeset, :body),
         nil <- get_field(changeset, :image) do
      add_error(changeset, :body, "image and comment content can't be blank at the same time")
    else
      _ -> changeset
    end
  end

  defp validate_tweet_and_comment(changeset) do
    with nil <- get_field(changeset, :tweet_id),
         nil <- get_field(changeset, :comment_id) do
      add_error(changeset, :body, "comment must belong to tweet or other comment")
    else
      _ -> changeset
    end
  end
end
