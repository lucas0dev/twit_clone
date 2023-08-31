defmodule TwitClone.TweetsTest do
  use TwitClone.DataCase

  alias TwitClone.Tweets

  describe "tweets" do
    alias TwitClone.Accounts.User
    alias TwitClone.Tweets.Tweet
    alias TwitClone.Repo

    import TwitClone.TweetsFixtures
    import TwitClone.AccountsFixtures

    @invalid_attrs %{"body" => nil, "image" => nil}

    test "list_tweets/0 returns all tweets" do
      tweet = tweet_fixture()
      result = Tweets.list_tweets()

      assert length(result) == 1
      assert List.first(result).id == tweet.id
    end

    test "get_tweet!/1 returns the tweet with given id" do
      tweet = tweet_fixture()
      assert Tweets.get_tweet!(tweet.id) == tweet
    end

    test "get_tweet_with_author/1 returns tweet map with user struct and comment_count" do
      tweet = tweet_fixture()
      result = Tweets.get_tweet_with_author(tweet.id)

      assert result.id == tweet.id
      assert %User{} = result.user
      assert result.comment_count == 0
    end

    test "get_tweet_with_assoc/1 returns tweet map with user struct and comments list" do
      tweet = tweet_fixture()
      comment = comment_fixture(tweet_id: tweet.id)
      result = Tweets.get_tweet_with_assoc(tweet.id)

      assert result.id == tweet.id
      assert %User{} = result.user
      assert length(result.comments) == 1
      assert List.first(result.comments).id == comment.id
    end

    test "create_tweet/2 with valid data creates a tweet" do
      user = user_fixture()
      image = "some image"
      valid_attrs = %{"body" => "some body", "image" => image}

      assert {:ok, %Tweet{} = tweet} = Tweets.create_tweet(valid_attrs, user.id)
      assert tweet.body == "some body"
      assert tweet.image == "some image"
    end

    test "create_tweet/2 with invalid data returns error changeset" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Tweets.create_tweet(@invalid_attrs, user.id)
    end

    test "create_tweet/2 with invalid data does not create a new tweet" do
      Tweets.create_tweet(@invalid_attrs)

      assert Repo.all(Tweet) == []
    end

    test "create_tweet/2 without user_id returns error changeset" do
      attrs = %{"body" => "some body"}

      assert {:error, %Ecto.Changeset{}} = Tweets.create_tweet(attrs)
    end

    test "create_tweet/2 without user_id data does not create a new tweet" do
      attrs = %{"body" => "some body"}
      Tweets.create_tweet(attrs)

      assert Repo.all(Tweet) == []
    end

    test "update_tweet/3 with valid data updates the tweet" do
      tweet = tweet_fixture()
      update_attrs = %{"body" => "some updated body"}

      assert {:ok, %Tweet{} = tweet} = Tweets.update_tweet(tweet, update_attrs, tweet.user_id)
      assert tweet.body == "some updated body"
    end

    test "update_tweet/3 with valid data deletes old image after updating it" do
      tweet = tweet_fixture()
      update_attrs = %{"body" => "some updated body", "image" => "another image"}
      old_image = tweet.image

      assert image_exists?(old_image) == true

      assert {:ok, %Tweet{} = updated_tweet} =
               Tweets.update_tweet(tweet, update_attrs, tweet.user_id)

      assert updated_tweet.body == "some updated body"
      assert updated_tweet.image == update_attrs["image"]
      assert image_exists?(old_image) == false
    end

    test "update_tweet/3 without new image does not change the old one" do
      tweet = tweet_fixture()
      update_attrs = %{"body" => "some updated body"}
      old_image = tweet.image

      assert image_exists?(old_image) == true

      assert {:ok, %Tweet{} = updated_tweet} =
               Tweets.update_tweet(tweet, update_attrs, tweet.user_id)

      assert updated_tweet.body == "some updated body"
      assert old_image == updated_tweet.image
      assert image_exists?(old_image) == true
    end

    test "update_tweet/3 with remove-image param true deletes the image" do
      tweet = tweet_fixture()
      update_attrs = %{"body" => "some updated body", "remove-image" => true, "image" => nil}
      old_image = tweet.image

      assert image_exists?(old_image) == true

      assert {:ok, %Tweet{} = updated_tweet} =
               Tweets.update_tweet(tweet, update_attrs, tweet.user_id)

      assert updated_tweet.body == "some updated body"
      assert updated_tweet.image == nil
      assert image_exists?(old_image) == false
    end

    test "update_tweet/3 with invalid data returns error changeset" do
      tweet = tweet_fixture()
      assert {:error, _} = Tweets.update_tweet(tweet, @invalid_attrs, tweet.user_id)
    end

    test "update_tweet/2 with invalid data does not update tweet" do
      tweet = tweet_fixture()
      Tweets.update_tweet(tweet, @invalid_attrs, tweet.user_id)
      assert tweet == Tweets.get_tweet!(tweet.id)
    end

    test "update_tweet/3 with attrs[:user_id] different than tweet.user_id returns error changeset" do
      second_user = user_fixture()
      tweet = tweet_fixture()
      attrs = %{"body" => "updated body"}

      assert {:error, _} = Tweets.update_tweet(tweet, attrs, second_user.id)
    end

    test "update_tweet/3 with user_id different than tweet.user_id does not update tweet" do
      second_user = user_fixture()
      tweet = tweet_fixture()
      attrs = %{"body" => "updated body"}

      Tweets.update_tweet(tweet, attrs, second_user.id)
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

    test "delete_tweet/2 with wrong user_id does not delete tweet" do
      tweet = tweet_fixture()
      result = Tweets.delete_tweet(tweet, 999)

      assert tweet == Tweets.get_tweet!(tweet.id)
      assert {:error, :wrong_user} == result
    end

    test "change_tweet/1 returns a tweet changeset" do
      tweet = tweet_fixture()
      assert %Ecto.Changeset{} = Tweets.change_tweet(tweet)
    end
  end

  describe "comments" do
    alias TwitClone.Accounts.User
    alias TwitClone.Tweets.Comment
    alias TwitClone.Tweets.Tweet
    alias TwitClone.Repo

    import TwitClone.TweetsFixtures
    import TwitClone.AccountsFixtures

    @invalid_attrs %{"body" => nil, "image" => nil}
    @valid_attrs %{"body" => "comment body"}
    @update_attrs %{"body" => "updated body"}

    test "get_comment!/1 returns comment with given id" do
      comment = comment_fixture()

      assert Tweets.get_comment!(comment.id) == comment
    end

    test "create_comment/2 with valid params creates new comment" do
      tweet = tweet_fixture()
      user = user_fixture()

      {:ok, comment} =
        Tweets.create_comment(@valid_attrs, %{"tweet_id" => tweet.id, "user_id" => user.id})

      assert comment.body == @valid_attrs["body"]
    end

    test "create_comment/2 with invalid params does not create a new comment" do
      tweet = tweet_fixture()
      user = user_fixture()

      result =
        Tweets.create_comment(@invalid_attrs, %{"tweet_id" => tweet.id, "user_id" => user.id})

      assert {:error, %Ecto.Changeset{}} = result
      assert Repo.all(Comment) == []
    end

    test "create_comment/2 with invalid assoc params does not create a new comment" do
      tweet = tweet_fixture()
      result = Tweets.create_comment(@valid_attrs, %{"tweet_id" => tweet.id, "user_id" => nil})

      assert {:error, %Ecto.Changeset{}} = result
      assert Repo.all(Comment) == []
    end

    test "update_comment/3 with valid params updates a comment" do
      comment = comment_fixture()
      {:ok, comment} = Tweets.update_comment(comment, @update_attrs, comment.user_id)

      assert comment.body == @update_attrs["body"]
    end

    test "update_comment/3 with invalid params does not update a comment" do
      comment = comment_fixture()
      result = Tweets.update_comment(comment, @invalid_attrs, comment.user_id)

      assert {:error, %Ecto.Changeset{}} = result
      assert Tweets.get_comment!(comment.id).body == comment.body
      assert Tweets.get_comment!(comment.id).image == comment.image
    end

    test "update_comment/3 with wrong user_id does not update a comment" do
      comment = comment_fixture()
      result = Tweets.update_comment(comment, @valid_attrs, 999)

      assert {:error, :wrong_user} = result
      assert Tweets.get_comment!(comment.id).body == comment.body
      assert Tweets.get_comment!(comment.id).image == comment.image
    end

    test "delete_comment/2 deletes the comment" do
      comment = comment_fixture()

      assert {:ok, %Comment{}} = Tweets.delete_comment(comment, comment.user_id)
      assert_raise Ecto.NoResultsError, fn -> Tweets.get_comment!(comment.id) end
    end

    test "delete_comment/2 deletes the comment image" do
      comment = comment_fixture()

      assert image_exists?(comment.image) == true
      assert {:ok, %Comment{}} = Tweets.delete_comment(comment, comment.user_id)
      assert_raise Ecto.NoResultsError, fn -> Tweets.get_comment!(comment.id) end
      assert image_exists?(comment.image) == false
    end

    test "delete_tweet/2 with wrong user_id does not delete comment" do
      comment = comment_fixture()
      result = Tweets.delete_comment(comment, 999)

      assert comment == Tweets.get_comment!(comment.id)
      assert {:error, :wrong_user} == result
    end

    test "change_comment/1 returns a comment changeset" do
      comment = comment_fixture()
      assert %Ecto.Changeset{} = Tweets.change_comment(comment)
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
end
