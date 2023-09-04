defmodule TwitClone.Tweets.Tweet do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias TwitClone.Accounts.User
  alias TwitClone.Tweets.Comment

  @type t :: %__MODULE__{}

  schema "tweets" do
    field :body, :string
    field :image, :string
    belongs_to :user, User

    has_many :comments, Comment,
      foreign_key: :parent_tweet_id,
      on_delete: :delete_all,
      preload_order: [desc: :id]

    timestamps()
  end

  @doc false
  def changeset(tweet, attrs) do
    tweet
    |> cast(attrs, [:body, :user_id, :image])
    |> validate_required([:user_id])
    |> validate_image_and_body()
    |> validate_length(:body, max: 280)
  end

  defp validate_image_and_body(changeset) do
    with nil <- get_field(changeset, :body),
         nil <- get_field(changeset, :image) do
      add_error(changeset, :body, "image and tweet content can't be blank at the same time")
    else
      _ -> changeset
    end
  end
end
