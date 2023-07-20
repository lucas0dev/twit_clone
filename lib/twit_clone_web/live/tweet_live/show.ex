defmodule TwitCloneWeb.TweetLive.Show do
  use TwitCloneWeb, :live_view

  import TwitCloneWeb.LiveHelpers

  alias TwitClone.Tweets
  alias TwitClone.Tweets.Comment
  alias TwitCloneWeb.SharedComponents

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
     |> assign(:reply_to, nil)
     |> stream(:comments, tweet.comments)}
  end

  @impl true
  def handle_event("assign_reply", %{"comment_id" => comment_id, "value" => _}, socket) do
    socket =
      push_event(socket, "add_form", %{
        to: "comment_#{comment_id}"
      })

    socket =
      assign(socket, :hidden_reply, false)
      |> assign(:reply_to, comment_id)

    {:noreply, socket}
  end

  defp page_title(:show), do: "Show Tweet"
  defp page_title(:edit), do: "Edit Tweet"
end
