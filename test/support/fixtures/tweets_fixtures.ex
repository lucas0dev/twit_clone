defmodule TwitClone.TweetsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `TwitClone.Tweets` context.
  """

  alias TwitClone.AccountsFixtures

  @doc """
  Generate a tweet.
  """
  def tweet_fixture(attrs \\ %{}, user_id \\ nil) do
    user_id = user_id || AccountsFixtures.user_fixture().id
    image = "test/support/test_image.jpg"
    dest = Path.join([:code.priv_dir(:twit_clone), "static", "uploads", random_string()])
    File.cp!(image, dest)
    path = "/uploads/#{Path.basename(dest)}"

    {:ok, tweet} =
      attrs
      |> Enum.into(%{
        body: "some body",
        user_id: user_id,
        image: path
      })
      |> TwitClone.Tweets.create_tweet()

    tweet
  end

  def random_string(length \\ 10) do
    :crypto.strong_rand_bytes(length) |> Base.url_encode64() |> binary_part(0, length)
  end

  @doc """
  Generate a comment.
  """
  def comment_fixture(attrs \\ %{}) do
    {:ok, comment} =
      attrs
      |> Enum.into(%{
        body: "some body",
        image: "some image"
      })
      |> TwitClone.Tweets.create_comment()

    comment
  end
end
