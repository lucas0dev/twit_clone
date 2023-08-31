defmodule TwitCloneWeb.TweetLive.Show do
  use TwitCloneWeb, :live_view

  import TwitCloneWeb.LiveHelpers

  alias TwitClone.Accounts.User
  alias TwitClone.Tweets
  alias TwitClone.Tweets.Comment
  alias TwitClone.Tweets.Tweet
  alias TwitCloneWeb.SharedComponents
  alias TwitCloneWeb.IconComponents

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user || %{id: nil, avatar: nil}

    socket =
      assign(socket, :user_id, user.id)
      |> assign(:avatar, user.avatar)

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    tweet = Tweets.get_tweet_with_assoc(id)
    comment = %Comment{tweet_id: tweet.id}

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:tweet, tweet)
     |> assign(:comment, comment)
     |> assign(:selected_comment, %Comment{})
     |> assign(:parent_tweet_id, nil)
     |> assign(:reply_to, nil)
     |> stream(:comments, tweet.comments)}
  end

  @impl true
  def handle_event("redirect", _, socket) do
    socket =
      redirect(socket, to: "/users/log_in")
      |> put_flash(:error, "You need to log in to do that.")

    {:noreply, socket}
  end

  @impl true
  def handle_event("set_comment", %{"comment_id" => comment_id}, socket) do
    comment = Tweets.get_comment!(comment_id)

    socket =
      push_event(socket, "show_modal", %{
        to: "edit-comment-modal"
      })
      |> assign(:selected_comment, comment)

    {:noreply, socket}
  end

  @impl true
  def handle_event("new_comment", %{"tweet_id" => tweet_id}, socket) do
    socket =
      push_event(socket, "append_comment_form", %{
        to: "tweet"
      })
      |> assign(:reply_to, nil)
      |> assign(:parent_tweet_id, tweet_id)

    {:noreply, socket}
  end

  @impl true
  def handle_event("new_comment", %{"comment_id" => comment_id}, socket) do
    socket =
      push_event(socket, "append_comment_form", %{
        to: "comment-#{comment_id}"
      })
      |> assign(:reply_to, comment_id)
      |> assign(:parent_tweet_id, nil)

    {:noreply, socket}
  end

  @spec tweet_owner?(User.t(), Tweet.t()) :: false | nil | true
  def tweet_owner?(user, tweet) do
    user && user.id == tweet.user_id
  end

  defp page_title(:show), do: "Show Tweet"
  defp page_title(:edit), do: "Edit Tweet"
end
