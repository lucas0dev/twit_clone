defmodule TwitClone.Tweets.Comment do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias TwitClone.Accounts.User
  alias TwitClone.Tweets.Comment
  alias TwitClone.Tweets.Tweet

  @type t :: %__MODULE__{}

  schema "tweets" do
    field :body, :string
    field :image, :string
    belongs_to :user, User
    belongs_to :parent_tweet, Tweet, foreign_key: :parent_tweet_id

    has_many :replies, Comment,
      foreign_key: :parent_tweet_id,
      on_delete: :nothing,
      preload_order: [desc: :id]

    timestamps()
  end

  @doc false
  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:body, :image, :user_id, :parent_tweet_id])
    |> validate_required([:user_id, :parent_tweet_id])
    |> validate_image_and_body()
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
end
