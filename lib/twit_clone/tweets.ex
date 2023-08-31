defmodule TwitClone.Tweets do
  @moduledoc false

  import Ecto.Query, warn: false

  alias TwitClone.Repo
  alias TwitClone.Tweets.Comment
  alias TwitClone.Tweets.Tweet
  alias TwitClone.MaybeDeleteImageService

  @tweet_fields Tweet.__schema__(:fields)
  @doc """
  Returns the list of tweets as a maps with added comment_count key and preloaded user.

  ## Examples

      iex> list_tweets()
      [%{body: tweet_body, comment_count: tweet_comment_couny, ...}, ...]

  """
  def list_tweets do
    query =
      from(t in Tweet,
        join: u in assoc(t, :user),
        on: t.user_id == u.id,
        left_join: c in assoc(t, :comments),
        preload: [user: u],
        group_by: [t.id, u.id],
        order_by: [desc: t.id],
        select: map(t, @tweet_fields),
        select_merge: %{comment_count: count(c.id)}
      )

    Repo.all(query)
  end

  @doc """
  Gets a single tweet.

  Raises `Ecto.NoResultsError` if the Tweet does not exist.

  ## Examples

      iex> get_tweet!(123)
      %Tweet{}

      iex> get_tweet!(456)
      ** (Ecto.NoResultsError)

  """
  def get_tweet!(id), do: Repo.get!(Tweet, id)

  @doc """
  Gets a single tweet as a map with added comment_count key and preloaded user.

  ## Examples

      iex> get_tweet_with_author(1)
      %{body: tweet_body, user: tweet_user, comment_count: comment_count, ...}

      iex> get_tweet_with_author(456)
      nil

  """
  def get_tweet_with_author(id) do
    query =
      from(t in Tweet,
        where: t.id == ^id,
        join: u in assoc(t, :user),
        on: t.user_id == u.id,
        left_join: c in assoc(t, :comments),
        preload: [user: u],
        group_by: [t.id, u.id],
        order_by: [desc: t.id],
        select: map(t, @tweet_fields),
        select_merge: %{comment_count: count(c.id)}
      )

    Repo.one(query)
  end

  @doc """
  Gets a single tweet with preloaded comments and user and preloaded data of comments.

  ## Examples

      iex> get_tweet_with_assoc(1)
      %{body: tweet_body, user: tweet_user, comments: comments, ...}

      iex> get_tweet_with_assoc(456)
      nil

  """
  def get_tweet_with_assoc(id) do
    query =
      from tweet in Tweet,
        where: tweet.id == ^id,
        join: user in assoc(tweet, :user),
        on: tweet.user_id == user.id,
        left_join: comment in assoc(tweet, :comments),
        on: ^id == comment.tweet_id,
        left_join: comment_user in assoc(comment, :user),
        on: comment.user_id == comment_user.id,
        left_join: reply in assoc(comment, :replies),
        on: comment.id == reply.comment_id,
        left_join: reply_user in assoc(reply, :user),
        on: reply.user_id == reply_user.id,
        preload: [
          user: user,
          comments: {comment, user: comment_user, replies: {reply, user: reply_user}}
        ],
        order_by: reply.id

    Repo.one(query)
  end

  @doc """
  Creates a tweet.

  ## Examples

      iex> create_tweet(%{field: value}, user_id, image_path)
      {:ok, %Tweet{}}

      iex> create_tweet(%{field: value})
      {:error, %Ecto.Changeset{}}

      iex> create_tweet(%{field: bad_value}, user_id, image_path)
      {:error, %Ecto.Changeset{}}

  """

  def create_tweet(attrs, user_id \\ nil) do
    attrs = Map.put(attrs, "user_id", user_id)

    %Tweet{}
    |> Tweet.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a tweet.

  ## Examples

      iex> update_tweet(tweet, %{field: new_value})
      {:ok, %Tweet{}}

      iex> update_tweet(tweet, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

      iex> update_tweet(tweet, %{field: new_value, user_id: nil})
      {:error, %{}}

  """
  def update_tweet(%Tweet{} = tweet, attrs, user_id) do
    with true <- tweet.user_id == user_id,
         {:ok, updated_tweet} <- Tweet.changeset(tweet, attrs) |> Repo.update() do
      MaybeDeleteImageService.run(tweet.image, attrs)
      {:ok, updated_tweet}
    else
      {:error, %Ecto.Changeset{} = changeset} -> {:error, changeset}
      _ -> {:error, :wrong_user}
    end
  end

  @doc """
  Deletes a tweet.

  ## Examples

      iex> delete_tweet(tweet, user_id)
      {:ok, %Tweet{}}

      iex> delete_tweet(tweet, user_id)
      {:error, %Ecto.Changeset{}}

       iex> delete_tweet(tweet, nil)
      {:error, %{}}

  """
  def delete_tweet(%Tweet{} = tweet, user_id) do
    with true <- tweet.user_id == user_id,
         {:ok, tweet} <- Repo.delete(tweet) do
      delete_image(tweet.image)
      {:ok, tweet}
    else
      {:error, changeset} -> {:error, changeset}
      _ -> {:error, :wrong_user}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking tweet changes.

  ## Examples

      iex> change_tweet(tweet)
      %Ecto.Changeset{data: %Tweet{}}

  """
  def change_tweet(%Tweet{} = tweet, attrs \\ %{}) do
    Tweet.changeset(tweet, attrs)
  end

  alias TwitClone.Tweets.Comment

  @doc """
  Gets a single comment.

  Raises `Ecto.NoResultsError` if the Comment does not exist.

  ## Examples

      iex> get_comment!(123)
      %Comment{}

      iex> get_comment!(456)
      ** (Ecto.NoResultsError)

  """
  def get_comment!(id), do: Repo.get!(Comment, id)

  def get_comment_with_replies(id) do
    query =
      from comment in Comment,
        where: comment.id == ^id,
        left_join: c in assoc(comment, :replies),
        preload: [
          replies: c
        ],
        order_by: c.inserted_at

    Repo.one(query)
  end

  @doc """
  Creates a comment.

  ## Examples

      iex> create_comment(%{field: value}, %{field: value})
      {:ok, %Comment{}}

      iex> create_comment(%{field: bad_value}, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_comment(attrs, assoc_params) do
    params =
      Enum.reduce(assoc_params, attrs, fn {key, value}, acc -> Map.put(acc, key, value) end)

    Comment.changeset(%Comment{}, params)
    |> Repo.insert()
  end

  @doc """
  Updates a comment.
  ## Examples

      iex> update_comment(comment, %{field: new_value}, user_id)
      {:ok, %Comment{}}

      iex> update_comment(comment, %{field: bad_value}, nil)
      {:error, %Ecto.Changeset{}}

  """
  def update_comment(%Comment{} = comment, attrs, user_id) do
    with true <- comment.user_id == user_id,
         {:ok, updated_comment} <- Comment.changeset(comment, attrs) |> Repo.update() do
      MaybeDeleteImageService.run(comment.image, attrs)
      {:ok, updated_comment}
    else
      {:error, %Ecto.Changeset{} = changeset} -> {:error, changeset}
      _ -> {:error, :wrong_user}
    end
  end

  @doc """
  Deletes a comment.

  ## Examples

      iex> delete_comment(comment)
      {:ok, %Comment{}}

      iex> delete_comment(comment)
      {:error, %Ecto.Changeset{}}

  """
  def delete_comment(%Comment{} = comment, user_id) do
    comment = get_comment_with_replies(comment.id)

    with true <- comment.user_id == user_id,
         [] <- comment.replies,
         {:ok, comment} <- Repo.delete(comment) do
      delete_image(comment.image)
      {:ok, comment}
    else
      {:error, _changeset} -> {:error, :changeset_error}
      false -> {:error, :wrong_user}
      _ -> {:error, :not_allowed}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking comment changes.

  ## Examples

      iex> change_comment(comment)
      %Ecto.Changeset{data: %Comment{}}

  """
  def change_comment(%Comment{} = comment, attrs \\ %{}) do
    Comment.changeset(comment, attrs)
  end

  def delete_image(path) do
    MaybeDeleteImageService.run(path)
  end
end
