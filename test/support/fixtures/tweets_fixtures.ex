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
        "body" => "some body",
        "image" => path
      })
      |> TwitClone.Tweets.create_tweet(user_id)

    tweet
  end

  @doc """
  Generate a comment.
  """
  def comment_fixture() do
    comment_fixture(%{}, %{})
  end

  def comment_fixture(attrs \\ %{}, assoc_params) do
    user_id = assoc_params[:user_id] || AccountsFixtures.user_fixture().id
    tweet_id = assoc_params[:tweet_id] || tweet_fixture().id
    comment_id = assoc_params[:comment_id]

    assoc_params =
      %{}
      |> Map.put("comment_id", comment_id)
      |> Map.put("user_id", user_id)
      |> Map.put("tweet_id", tweet_id)

    image = "test/support/test_image.jpg"
    dest = Path.join([:code.priv_dir(:twit_clone), "static", "uploads", random_string()])
    File.cp!(image, dest)
    path = "/uploads/#{Path.basename(dest)}"

    {:ok, comment} =
      attrs
      |> Enum.into(%{
        "body" => "some body",
        "image" => path
      })
      |> TwitClone.Tweets.create_comment(assoc_params)

    comment
  end

  def random_string(length \\ 10) do
    :crypto.strong_rand_bytes(length) |> Base.url_encode64() |> binary_part(0, length)
  end
end
