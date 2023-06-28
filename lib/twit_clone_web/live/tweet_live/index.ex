defmodule TwitCloneWeb.TweetLive.Index do
  use TwitCloneWeb, :live_view

  alias TwitClone.Tweets
  alias TwitClone.Tweets.Tweet

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    user_id =
      if user do
        user.id
      else
        nil
      end

    socket = assign(socket, :user_id, user_id)
    {:ok, stream(socket, :tweets, Tweets.list_tweets())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Tweet")
    |> assign(:tweet, Tweets.get_tweet!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Tweet")
    |> assign(:tweet, %Tweet{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Tweets")
    |> assign(:tweet, nil)
  end

  @impl true
  def handle_info({TwitCloneWeb.TweetLive.FormComponent, {:saved, tweet}}, socket) do
    {:noreply, stream_insert(socket, :tweets, tweet)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    tweet = Tweets.get_tweet!(id)
    user_id = socket.assigns.user_id

    case Tweets.delete_tweet(tweet, user_id) do
      {:ok, _} ->
        {:noreply, stream_delete(socket, :tweets, tweet)}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, "You can't delete someoen else's tweets.")}
    end
  end
end
