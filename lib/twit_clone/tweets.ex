defmodule TwitClone.Tweets do
  @moduledoc false

  import Ecto.Query, warn: false
  alias TwitClone.Repo
  alias TwitClone.Tweets.Tweet

  @doc """
  Returns the list of tweets.

  ## Examples

      iex> list_tweets()
      [%Tweet{}, ...]

  """
  def list_tweets do
    Repo.all(Tweet)
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
  Creates a tweet.

  ## Examples

      iex> create_tweet(%{field: value}, user_id, image_path)
      {:ok, %Tweet{}}

      iex> create_tweet(%{field: value})
      {:error, %Ecto.Changeset{}}

      iex> create_tweet(%{field: bad_value}, user_id, image_path)
      {:error, %Ecto.Changeset{}}

  """

  def create_tweet(attrs \\ %{}) do
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
  def update_tweet(%Tweet{} = tweet, attrs) do
    with true <- tweet.user_id == attrs.user_id,
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
    full_path =
      Path.join([
        :code.priv_dir(:twit_clone),
        "static",
        "/#{path}"
      ])

    File.rm(full_path)
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
end
