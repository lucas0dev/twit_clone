defmodule TwitCloneWeb.CommentLive.ActionsComponent do
  use Phoenix.LiveComponent

  alias TwitClone.Tweets
  alias Phoenix.LiveView.JS

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id={"c-actions-#{@comment.id}" }
      class=" absolute right-0 top-[8px] z-10 hidden border-2 bg-white divide-y divide-gray-100  shadow w-44 "
      phx-click-away={JS.hide(transition: "fade-out", to: "#c-actions-#{@comment.id}")}
      phx-window-keydown={JS.hide(transition: "fade-out", to: "#c-actions-#{@comment.id}")}
      phx-key="escape"
    >
      <ul class="text-sm text-gray-700 dark:text-gray-200" aria-labelledby="dropdownDefaultButton">
        <li>
          <.link
            phx-click={JS.push("set_comment", value: %{comment_id: @comment.id})}
            class="text-black block px-4 py-2 hover:bg-gray-100 dark:hover:bg-gray-600 dark:hover:text-white"
          >
            Edit
          </.link>
        </li>
        <li>
          <a
            phx-click="delete"
            phx-value-id={@comment.id}
            phx-target={@myself}
            class="text-black block px-4 py-2 hover:bg-gray-100 dark:hover:bg-gray-600 dark:hover:text-white"
          >
            Delete
          </a>
        </li>
      </ul>
    </div>
    """
  end

  @impl true
  def update(%{comment: comment, user_id: user_id} = _assigns, socket) do
    socket =
      socket
      |> assign(:user_id, user_id)
      |> assign(:comment, comment)

    {:ok, socket}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    comment = Tweets.get_comment!(id)
    user_id = socket.assigns.user_id

    case Tweets.delete_comment(comment, user_id) do
      {:ok, _} ->
        socket = after_delete_reponse(comment, socket)
        {:noreply, socket}

      {:error, msg} ->
        {:noreply,
         socket
         |> put_flash(:error, error_to_string(msg))
         |> push_navigate(to: "/tweets/#{comment.tweet_id}")}
    end
  end

  defp after_delete_reponse(comment, socket) do
    notify_parent({:deleted, comment})

    socket
    |> put_flash(:info, "Comment deleted")
    |> push_navigate(to: "/tweets/#{comment.tweet_id}")
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp error_to_string(:changeset_error), do: "You can't do that."
  defp error_to_string(:wrong_user), do: "You can't delete someone else's comment."
  defp error_to_string(:not_allowed), do: "You can't delete comment with replies."
end
