defmodule TwitCloneWeb.TweetLive.Show do
  use TwitCloneWeb, :live_view

  alias TwitClone.Tweets

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    user_id =
      if user do
        user.id
      else
        nil
      end

    {:ok, assign(socket, :user_id, user_id)}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:tweet, Tweets.get_tweet!(id))}
  end

  defp page_title(:show), do: "Show Tweet"
  defp page_title(:edit), do: "Edit Tweet"
end
