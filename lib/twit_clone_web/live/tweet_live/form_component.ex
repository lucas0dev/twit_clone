defmodule TwitCloneWeb.TweetLive.FormComponent do
  use TwitCloneWeb, :live_component

  alias TwitClone.Tweets

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
        <.input field={@form[:body]} type="textarea" label="Tweet" maxlength="280" />
        <%= if @uploads.image.entries == [] do %>
          <img class="tweet-image" src={@tweet.image} />
        <% end %>
        <%= for entry <- @uploads.image.entries do %>
          <article>
            <div class="image-preview">
              <.live_img_preview entry={entry} />
            </div>
            <progress value={entry.progress} max="100"><%= entry.progress %>%</progress>
            <button
              type="button"
              id="cancel-upload"
              phx-click="cancel-upload"
              phx-target={@myself}
              phx-value-ref={entry.ref}
              aria-label="cancel"
            >
              &times;
            </button>
          </article>
        <% end %>
        <.live_file_input upload={@uploads.image} />

        <div
          :for={{_num, err} <- @uploads.image.errors}
          class="mt-3 flex gap-3 text-sm leading-6 text-rose-600 phx-no-feedback:hidden"
        >
          <%= error_to_string(err) %>
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
     |> assign_form(changeset)
     |> allow_upload(:image, accept: ~w(.jpg .jpeg .png), max_entries: 1, auto_upload: true)}
  end

  @impl true
  def handle_event("validate", %{"tweet" => tweet_params}, socket) do
    changeset =
      socket.assigns.tweet
      |> Tweets.change_tweet(tweet_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"tweet" => tweet_params}, socket) do
    save_tweet(socket, socket.assigns.action, tweet_params)
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :image, ref)}
  end

  defp save_tweet(socket, :new, tweet_params) do
    user_id = socket.assigns.user_id
    tweet_params = maybe_add_uploaded_image(tweet_params, socket)

    case Tweets.create_tweet(tweet_params, user_id) do
      {:ok, tweet} ->
        notify_parent({:saved, tweet})

        {:noreply,
         socket
         |> put_flash(:info, "Tweet created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        Tweets.delete_image(tweet_params.image)
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_tweet(socket, :edit, tweet_params) do
    user_id = socket.assigns.user_id
    tweet_params = maybe_add_uploaded_image(tweet_params, socket)

    case Tweets.update_tweet(socket.assigns.tweet, tweet_params, user_id) do
      {:ok, tweet} ->
        notify_parent({:saved, tweet})

        {:noreply,
         socket
         |> put_flash(:info, "Tweet updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        Tweets.delete_image(tweet_params.image)
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp maybe_add_uploaded_image(tweet_params, socket) do
    response =
      consume_uploaded_entries(socket, :image, fn %{path: path}, entry ->
        if entry.cancelled? == false do
          dest =
            Path.join([:code.priv_dir(:twit_clone), "static", "uploads", Path.basename(path)])

          File.cp!(path, dest)
          {:ok, ~p"/uploads/#{Path.basename(dest)}"}
        end
      end)

    Map.put(tweet_params, "image", List.first(response))
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
  defp error_to_string(:too_many_files), do: "You have selected too many files"
end
