defmodule TwitCloneWeb.TweetLive.Index do
  use TwitCloneWeb, :live_view

  import TwitCloneWeb.LiveHelpers

  alias TwitClone.Tweets
  alias TwitClone.Tweets.Comment
  alias TwitClone.Tweets.Tweet
  alias TwitCloneWeb.SharedComponents


  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user || %{id: nil, avatar: nil}

    socket =
      assign(socket, :user_id, user.id)
      |> assign(:avatar, user.avatar)
      |> assign(:tweet_id, nil)
      |> assign(:comment, nil)

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
    tweet = Tweets.get_tweet_with_author(tweet.id)

    {:noreply, stream_insert(socket, :tweets, tweet, at: 0)}
  end

  @impl true
  def handle_event("show_tweet", %{"tweet_id" => id}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/tweets/#{id}")}
  end

  @impl true
  def handle_event("show_options", %{"tweet_id" => _id}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("hide_options", %{"tweet_id" => id}, socket) do
    hide_options(id)
    {:noreply, socket}
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

  def handle_event("new_comment", %{"tweet_id" => tweet_id, "value" => _}, socket) do
    socket =
      assign(socket, :tweet_id, tweet_id)
      |> assign(:comment, %Comment{})

    {:noreply, socket}
  end

  defp hide_options(id) do
    JS.hide(transition: "fade-out", to: "#actions-#{id}")
  end
end
