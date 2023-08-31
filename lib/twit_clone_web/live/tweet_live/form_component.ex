defmodule TwitCloneWeb.TweetLive.FormComponent do
  use TwitCloneWeb, :live_component

  alias TwitClone.Tweets
  alias TwitCloneWeb.TweetLive.UploadsComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage tweet records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="tweet-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input id="tweet-body" field={@form[:body]} type="textarea" label="Tweet" maxlength="280" />
        <%= if @uploads.image.entries == [] && @tweet_image != nil do %>
          <img class="tweet-image max-h-80 mx-auto border rounded-md" src={@tweet_image} />
        <% end %>
        <div class="mx-auto">
          <.live_component
            module={UploadsComponent}
            uploads={@uploads}
            id={"upload_#{random_string(6)}"}
            validate_target="tweet-body"
            preview_class="max-h-80 mx-auto"
            input_label="Add image"
          />
          <%= if @tweet_image != nil do %>
            <div class="w-fit mx-auto">
              <button
                class="border-2 p-1 rounded-md w-full"
                type="button"
                id="remove-image"
                phx-click="remove-image"
                aria-label="remove image"
                phx-target={@myself}
              >
                Remove image
              </button>
            </div>
          <% end %>
        </div>
        <:actions>
          <.button phx-disable-with="Saving...">Save Tweet</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{tweet: tweet} = assigns, socket) do
    changeset = Tweets.change_tweet(tweet)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:tweet_image, tweet.image)
     |> assign_form(changeset)
     |> assign(:source, assigns.source)
     |> allow_upload(:image, accept: ~w(.jpg .jpeg .png), max_entries: 1, auto_upload: true)}
  end

  @impl true
  def handle_event("validate", %{"tweet" => tweet_params}, socket) do
    image_name = if UploadsComponent.image_added?(socket), do: "temporary_name", else: nil
    tweet_params = Map.put(tweet_params, "image", image_name)

    changeset =
      socket.assigns.tweet
      |> Tweets.change_tweet(tweet_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"tweet" => tweet_params}, socket) do
    save_tweet(socket, socket.assigns.action, tweet_params)
  end

  def handle_event("remove-image", _, socket) do
    socket =
      socket
      |> assign(:remove_image, true)
      |> assign(:tweet_image, nil)

    {:noreply, socket}
  end

  defp save_tweet(socket, :new, tweet_params) do
    user_id = socket.assigns.user_id
    tweet_params = UploadsComponent.maybe_update_image(socket, tweet_params, "image")

    case Tweets.create_tweet(tweet_params, user_id) do
      {:ok, tweet} ->
        notify_parent({:saved, tweet})

        {:noreply,
         socket
         |> put_flash(:info, "Tweet created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        Tweets.delete_image(tweet_params["image"])
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_tweet(socket, :edit, tweet_params) do
    user_id = socket.assigns.user_id
    source = socket.assigns.source
    tweet_params = UploadsComponent.maybe_update_image(socket, tweet_params, "image")

    case Tweets.update_tweet(socket.assigns.tweet, tweet_params, user_id) do
      {:ok, tweet} ->
        socket = assign(socket, :tweet_image, tweet.image)
        {:noreply, succesful_edit_reponse(tweet, source, socket)}

      {:error, %Ecto.Changeset{} = changeset} ->
        Tweets.delete_image(tweet_params["image"])
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp succesful_edit_reponse(tweet, :index, socket) do
    notify_parent({:saved, tweet})

    socket
    |> put_flash(:info, "Tweet updated successfully")
    |> push_patch(to: socket.assigns.patch)
  end

  defp succesful_edit_reponse(_tweet, :show, socket) do
    socket
    |> put_flash(:info, "Tweet updated successfully")
    |> push_navigate(to: socket.assigns.patch)
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp random_string(bytes_count) do
    bytes_count
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end
end
