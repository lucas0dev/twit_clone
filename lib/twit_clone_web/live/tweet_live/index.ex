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
      |> assign(:parent_tweet_id, nil)

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

  def handle_info({_, {:deleted, tweet}}, socket) do
    {:noreply, stream_delete(socket, :tweets, tweet)}
  end

  @impl true
  def handle_event("show_tweet", %{"tweet_id" => id}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/tweets/#{id}")}
  end

  def handle_event("new_comment", %{"tweet_id" => tweet_id}, socket) do
    socket =
      assign(socket, :parent_tweet_id, tweet_id)
      |> assign(:comment, %Comment{})
      |> push_event("show_modal", %{
        to: "comment-modal"
      })

    {:noreply, socket}
  end

  def handle_event("redirect", _, socket) do
    socket =
      redirect(socket, to: "/users/log_in")
      |> put_flash(:error, "You need to log in to do that.")

    {:noreply, socket}
  end

  def tweet_owner?(user, tweet) do
    user && user.id == tweet.user_id
  end
end
