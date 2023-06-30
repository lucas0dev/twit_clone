defmodule TwitClone.TweetsTest do
  use TwitClone.DataCase

  alias TwitClone.Tweets

  describe "tweets" do
    alias TwitClone.Tweets.Tweet
    alias TwitClone.Repo

    import TwitClone.TweetsFixtures
    import TwitClone.AccountsFixtures

    @invalid_attrs %{body: nil, user_id: nil}

    setup do
      on_exit(fn -> delete_images() end)
    end

    test "list_tweets/0 returns all tweets" do
      tweet = tweet_fixture()
      assert Tweets.list_tweets() == [tweet]
    end

    test "get_tweet!/1 returns the tweet with given id" do
      tweet = tweet_fixture()
      assert Tweets.get_tweet!(tweet.id) == tweet
    end

    test "create_tweet/1 with valid data creates a tweet" do
      user = user_fixture()
      image = "some image"
      valid_attrs = %{body: "some body", user_id: user.id, image: image}

      assert {:ok, %Tweet{} = tweet} = Tweets.create_tweet(valid_attrs)
      assert tweet.body == "some body"
      assert tweet.image == "some image"
    end

    test "create_tweet/1 without params returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Tweets.create_tweet()
    end

    test "create_tweet/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Tweets.create_tweet(@invalid_attrs)
    end

    test "create_tweet/1 with invalid data does not create a new tweet" do
      Tweets.create_tweet(@invalid_attrs)

      assert Repo.all(Tweet) == []
    end

    test "create_tweet/1 without user_id returns error changeset" do
      attrs = %{body: "some body"}

      assert {:error, %Ecto.Changeset{}} = Tweets.create_tweet(attrs)
    end

    test "create_tweet/1 without user_id data does not create a new tweet" do
      attrs = %{body: "some body"}
      Tweets.create_tweet(attrs)

      assert Repo.all(Tweet) == []
    end

    test "update_tweet/2 with valid data updates the tweet" do
      tweet = tweet_fixture()
      update_attrs = %{body: "some updated body", user_id: tweet.user_id}

      assert {:ok, %Tweet{} = tweet} = Tweets.update_tweet(tweet, update_attrs)
      assert tweet.body == "some updated body"
    end

    test "update_tweet/2 with valid data deletes old image after updating it" do
      tweet = tweet_fixture()
      update_attrs = %{body: "some updated body", user_id: tweet.user_id, image: "another image"}
      old_image = tweet.image

      assert image_exists?(old_image) == true
      assert {:ok, %Tweet{} = updated_tweet} = Tweets.update_tweet(tweet, update_attrs)
      assert updated_tweet.body == "some updated body"
      assert image_exists?(old_image) == false
    end

    test "update_tweet/2 without new image does not change the old one" do
      tweet = tweet_fixture()
      update_attrs = %{body: "some updated body", user_id: tweet.user_id}
      old_image = tweet.image

      assert image_exists?(old_image) == true
      assert {:ok, %Tweet{} = updated_tweet} = Tweets.update_tweet(tweet, update_attrs)
      assert updated_tweet.body == "some updated body"
      assert old_image == updated_tweet.image
      assert image_exists?(old_image) == true
    end

    test "update_tweet/2 with invalid data returns error changeset" do
      tweet = tweet_fixture()
      assert {:error, _} = Tweets.update_tweet(tweet, @invalid_attrs)
    end

    test "update_tweet/2 with invalid data does not update tweet" do
      tweet = tweet_fixture()
      Tweets.update_tweet(tweet, @invalid_attrs)
      assert tweet == Tweets.get_tweet!(tweet.id)
    end

    test "update_tweet/2 with attrs[:user_id] different than tweet.user_id returns error changeset" do
      second_user = user_fixture()
      tweet = tweet_fixture()
      attrs = %{body: "updated body", user_id: second_user.id}

      assert {:error, _} = Tweets.update_tweet(tweet, attrs)
    end

    test "update_tweet/2 with user_id different than tweet.user_id does not update tweet" do
      second_user = user_fixture()
      tweet = tweet_fixture()
      attrs = %{body: "updated body", user_id: second_user.id}

      Tweets.update_tweet(tweet, attrs)
      assert tweet == Tweets.get_tweet!(tweet.id)
    end

    test "delete_tweet/2 deletes the tweet" do
      tweet = tweet_fixture()
      assert {:ok, %Tweet{}} = Tweets.delete_tweet(tweet, tweet.user_id)
      assert_raise Ecto.NoResultsError, fn -> Tweets.get_tweet!(tweet.id) end
    end

    test "delete_tweet/2 deletes the tweet image" do
      tweet = tweet_fixture()

      assert image_exists?(tweet.image) == true
      assert {:ok, %Tweet{}} = Tweets.delete_tweet(tweet, tweet.user_id)
      assert_raise Ecto.NoResultsError, fn -> Tweets.get_tweet!(tweet.id) end
      assert image_exists?(tweet.image) == false
    end

    test "delete_tweet/2 without user_id returns {:error, _} tuple" do
      tweet = tweet_fixture()
      assert {:error, _} = Tweets.delete_tweet(tweet)
    end

    test "delete_tweet/2 without user_id does not delete tweet" do
      tweet = tweet_fixture()
      Tweets.delete_tweet(tweet)
      assert tweet == Tweets.get_tweet!(tweet.id)
    end

    test "delete_tweet/2 with user_id different than tweet.user_id returns {:error, _} tuple" do
      second_user = user_fixture()
      tweet = tweet_fixture()
      assert {:error, _} = Tweets.delete_tweet(tweet, second_user.id)
    end

    test "delete_tweet/2 with user_id different than tweet.user_id does not delete tweet" do
      second_user = user_fixture()
      tweet = tweet_fixture()
      Tweets.delete_tweet(tweet, second_user.id)
      assert tweet == Tweets.get_tweet!(tweet.id)
    end

    test "change_tweet/1 returns a tweet changeset" do
      tweet = tweet_fixture()
      assert %Ecto.Changeset{} = Tweets.change_tweet(tweet)
    end
  end

  defp image_exists?(image_path) do
    full_path =
      Path.join([
        :code.priv_dir(:twit_clone),
        "static",
        "/#{image_path}"
      ])

    File.exists?(full_path)
  end

  defp delete_images() do
    path =
      Path.join([
        :code.priv_dir(:twit_clone),
        "static",
        "uploads/"
      ])

    File.rm_rf(path)
    File.mkdir(path)
  end

  # describe "comments" do
  #   alias TwitClone.Tweets.Comment

  #   import TwitClone.TweetsFixtures

  #   @invalid_attrs %{body: nil, image: nil}

  #   test "list_comments/0 returns all comments" do
  #     comment = comment_fixture()
  #     assert Tweets.list_comments() == [comment]
  #   end

  #   test "get_comment!/1 returns the comment with given id" do
  #     comment = comment_fixture()
  #     assert Tweets.get_comment!(comment.id) == comment
  #   end

  #   test "create_comment/1 with valid data creates a comment" do
  #     valid_attrs = %{body: "some body", image: "some image"}

  #     assert {:ok, %Comment{} = comment} = Tweets.create_comment(valid_attrs)
  #     assert comment.body == "some body"
  #     assert comment.image == "some image"
  #   end

  #   test "create_comment/1 with invalid data returns error changeset" do
  #     assert {:error, %Ecto.Changeset{}} = Tweets.create_comment(@invalid_attrs)
  #   end

  #   test "update_comment/2 with valid data updates the comment" do
  #     comment = comment_fixture()
  #     update_attrs = %{body: "some updated body", image: "some updated image"}

  #     assert {:ok, %Comment{} = comment} = Tweets.update_comment(comment, update_attrs)
  #     assert comment.body == "some updated body"
  #     assert comment.image == "some updated image"
  #   end

  #   test "update_comment/2 with invalid data returns error changeset" do
  #     comment = comment_fixture()
  #     assert {:error, %Ecto.Changeset{}} = Tweets.update_comment(comment, @invalid_attrs)
  #     assert comment == Tweets.get_comment!(comment.id)
  #   end

  #   test "delete_comment/1 deletes the comment" do
  #     comment = comment_fixture()
  #     assert {:ok, %Comment{}} = Tweets.delete_comment(comment)
  #     assert_raise Ecto.NoResultsError, fn -> Tweets.get_comment!(comment.id) end
  #   end

  #   test "change_comment/1 returns a comment changeset" do
  #     comment = comment_fixture()
  #     assert %Ecto.Changeset{} = Tweets.change_comment(comment)
  #   end
  # end
end
