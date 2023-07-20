defmodule TwitClone.Tweets do
  @moduledoc false

  import Ecto.Query, warn: false

  alias TwitClone.Repo
  alias TwitClone.Tweets.Comment
  alias TwitClone.Tweets.Tweet
  alias TwitClone.UploadHelper

  @tweet_fields Tweet.__schema__(:fields)
  @doc """
  Returns the list of tweets.

  ## Examples

      iex> list_tweets()
      [%Tweet{}, ...]

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
        order_by: comment.id,
        preload: [
          user: user,
          comments: {comment, user: comment_user, replies: {reply, user: reply_user}}
        ]

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

  def create_tweet(attrs \\ %{}, user_id) do
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
      maybe_delete_image(tweet, attrs)
      {:ok, updated_tweet}
    else
      {:error, %Ecto.Changeset{} = changeset} -> {:error, changeset}
      _ -> {:error, %{}}
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
  def delete_tweet(%Tweet{} = tweet, user_id \\ nil) do
    with true <- tweet.user_id == user_id,
         {:ok, tweet} <- Repo.delete(tweet) do
      delete_image(tweet.image)
      {:ok, tweet}
    else
      {:error, changeset} -> {:error, changeset}
      _ -> {:error, %{}}
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

  def prepare_params(params, user_id, image_path) do
    body =
      key_to_atom(params)
      |> Map.get(:body, nil)

    params =
      %{body: body}
      |> Map.put(:user_id, user_id)

    case image_path do
      :delete -> Map.put(params, :image, nil)
      nil -> params
      new_image_path -> Map.put(params, :image, new_image_path)
    end
  end

  def delete_image(path) do
    UploadHelper.delete_image(path)
  end

  defp maybe_delete_image(tweet, params) do
    case params[:image] do
      nil -> :ok
      _ -> delete_image(tweet.image)
    end
  end

  defp key_to_atom(attrs) do
    Enum.reduce(attrs, %{}, fn
      {key, value}, acc when is_atom(key) -> Map.put(acc, key, value)
      {key, value}, acc when is_binary(key) -> Map.put(acc, String.to_existing_atom(key), value)
    end)
  end

  alias TwitClone.Tweets.Comment

  @doc """
  Returns the list of comments.

  ## Examples

      iex> list_comments()
      [%Comment{}, ...]

  """
  def list_comments do
    Repo.all(Comment)
  end

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

  @doc """
  Creates a comment.

  ## Examples

      iex> create_comment(%{field: value})
      {:ok, %Comment{}}

      iex> create_comment(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_comment(attrs \\ %{}, assoc_params) do
    params =
      Enum.reduce(assoc_params, attrs, fn {key, value}, acc -> Map.put(acc, key, value) end)

    Comment.changeset(%Comment{}, params)
    |> Repo.insert()
  end

  @doc """
  Updates a comment.

  ## Examples

      iex> update_comment(comment, %{field: new_value})
      {:ok, %Comment{}}

      iex> update_comment(comment, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_comment(%Comment{} = comment, attrs) do
    comment
    |> Comment.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a comment.

  ## Examples

      iex> delete_comment(comment)
      {:ok, %Comment{}}

      iex> delete_comment(comment)
      {:error, %Ecto.Changeset{}}

  """
  def delete_comment(%Comment{} = comment) do
    Repo.delete(comment)
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
end
