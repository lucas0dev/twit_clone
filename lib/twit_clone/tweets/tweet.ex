defmodule TwitClone.Tweets.Tweet do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias TwitClone.Accounts.User
  alias TwitClone.Tweets.Comment

  schema "tweets" do
    field :body, :string
    field :image, :string
    belongs_to :user, User

    has_many :comments, Comment,
      foreign_key: :tweet_id,
      on_delete: :delete_all,
      preload_order: [desc: :id]

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
