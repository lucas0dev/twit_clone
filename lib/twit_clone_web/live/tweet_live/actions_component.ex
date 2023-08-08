defmodule TwitCloneWeb.TweetLive.ActionsComponent do
  use Phoenix.LiveComponent

  import TwitCloneWeb.CoreComponents, only: [show_modal: 1]

  alias TwitClone.Tweets
  alias Phoenix.LiveView.JS

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id={"actions-#{@tweet_id}" }
      class=" absolute right-0 top-[8px] z-10 hidden border-2 bg-white divide-y divide-gray-100  shadow w-44 "
      phx-click-away={
        JS.hide(transition: "fade-out", to: "#actions-#{@tweet_id}")
        |> JS.set_attribute({"phx-click", "show_tweet"}, to: ".tweet")
      }
      phx-window-keydown={
        JS.hide(transition: "fade-out", to: "#actions-#{@tweet_id}")
        |> JS.set_attribute({"phx-click", "show_tweet"}, to: ".tweet")
      }
      phx-key="escape"
    >
      <ul class="text-sm text-gray-700 dark:text-gray-200" aria-labelledby="dropdownDefaultButton">
        <li>
          <%= if @source == :index do %>
            <.link
              patch={"/tweets/#{@tweet_id}/edit"}
              class="text-black block px-4 py-2 hover:bg-gray-100 dark:hover:bg-gray-600 dark:hover:text-white"
            >
              Edit
            </.link>
          <% end %>
          <%= if @source == :show do %>
            <.link
              phx-click={show_modal("edit_tweet_form")}
              class="text-black block px-4 py-2 hover:bg-gray-100 dark:hover:bg-gray-600 dark:hover:text-white"
            >
              Edit
            </.link>
          <% end %>
        </li>
        <li>
          <a
            id={"delete-#{@tweet_id}"}
            phx-click={
              JS.push("delete") |> JS.set_attribute({"phx-click", "show_tweet"}, to: ".tweet")
            }
            phx-value-id={@tweet_id}
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
  def update(%{tweet_id: tweet_id} = assigns, socket) do
    socket =
      socket
      |> assign(:user_id, assigns.user_id)
      |> assign(:tweet_id, tweet_id)
      |> assign(:source, assigns.source)
      |> assign(:patch, assigns.patch)

    {:ok, socket}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    tweet = Tweets.get_tweet!(id)
    user_id = socket.assigns.user_id
    source = socket.assigns.source

    case Tweets.delete_tweet(tweet, user_id) do
      {:ok, _} ->
        socket = after_delete_reponse(tweet, source, socket)
        {:noreply, socket}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, "You can't delete someone else's tweets.")
         |> push_patch(to: socket.assigns.patch)}
    end
  end

  defp after_delete_reponse(tweet, :index, socket) do
    notify_parent({:deleted, tweet})

    socket
    |> put_flash(:info, "Tweet deleted")
    |> push_patch(to: "/")
  end

  defp after_delete_reponse(_tweet, :show, socket) do
    socket
    |> put_flash(:info, "Tweet deleted")
    |> push_navigate(to: "/")
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
