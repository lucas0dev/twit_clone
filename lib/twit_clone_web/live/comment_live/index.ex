defmodule TwitCloneWeb.CommentLive.Index do
  use TwitCloneWeb, :live_view

  alias TwitClone.Tweets
  alias TwitClone.Tweets.Comment

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :comments, Tweets.list_comments())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Comment")
    |> assign(:comment, Tweets.get_comment!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Comment")
    |> assign(:comment, %Comment{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Comments")
    |> assign(:comment, nil)
  end

  @impl true
  def handle_info({TwitCloneWeb.CommentLive.FormComponent, {:saved, comment}}, socket) do
    {:noreply, stream_insert(socket, :comments, comment)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    comment = Tweets.get_comment!(id)
    {:ok, _} = Tweets.delete_comment(comment)

    {:noreply, stream_delete(socket, :comments, comment)}
  end
end
