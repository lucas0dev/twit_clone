defmodule TwitCloneWeb.CommentLive.FormComponent do
  use TwitCloneWeb, :live_component

  alias TwitClone.Tweets

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-row py-4 px-2 w-full">
      <div class="flex flex-row w-full items-start">
        <img class="h-12 w-12 rounded-full" src={@avatar} />
        <.simple_form
          for={@form}
          id={"form_#{random_string(6)}"}
          class="ml-2 flex-1"
          phx-target={@myself}
          phx-change="validate"
          phx-submit="save"
        >
          <.input
            class="-mt-2"
            id={"form_body_#{random_string(6)}"}
            field={@form[:body]}
            type="textarea"
            maxlength="280"
            placeholder="Add a comment"
          />
          <%= for entry <- @uploads[@image].entries do %>
            <.live_img_preview entry={entry} class="max-h-80 mx-auto" />
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
          <% end %>
          <div class=" flex flex-row max-w-sm ">
            <.live_file_input
              phx-click="cancel-upload"
              phx-target={@myself}
              upload={@uploads[@image]}
            />
          </div>
          <:actions>
            <.button phx-disable-with="Saving..." class="right ml-auto">Send</.button>
          </:actions>
        </.simple_form>
        <%= if @hidden do %>
          <button class="px-2 w-8" phx-click={JS.add_class("hidden", to: "#hidden_form")}>
            <svg
              version="1.1"
              xmlns="http://www.w3.org/2000/svg"
              xmlns:xlink="http://www.w3.org/1999/xlink"
              viewBox="0 0 26 26"
              xml:space="preserve"
              fill="#000000"
            >
              <g stroke-width="0"></g>
              <g stroke-linecap="round" stroke-linejoin="round"></g>
              <g>
                <g>
                  <path
                    style="fill:#030104;"
                    d="M21.125,0H4.875C2.182,0,0,2.182,0,4.875v16.25C0,23.818,2.182,26,4.875,26h16.25 C23.818,26,26,23.818,26,21.125V4.875C26,2.182,23.818,0,21.125,0z M18.78,17.394l-1.388,1.387c-0.254,0.255-0.67,0.255-0.924,0 L13,15.313L9.533,18.78c-0.255,0.255-0.67,0.255-0.925-0.002L7.22,17.394c-0.253-0.256-0.253-0.669,0-0.926l3.468-3.467 L7.221,9.534c-0.254-0.256-0.254-0.672,0-0.925l1.388-1.388c0.255-0.257,0.671-0.257,0.925,0L13,10.689l3.468-3.468 c0.255-0.257,0.671-0.257,0.924,0l1.388,1.386c0.254,0.255,0.254,0.671,0.001,0.927l-3.468,3.467l3.468,3.467 C19.033,16.725,19.033,17.138,18.78,17.394z"
                  >
                  </path>
                </g>
              </g>
            </svg>
          </button>
        <% end %>
      </div>
    </div>
    """
  end

  @impl true
  def update(%{comment: comment} = assigns, socket) do
    changeset = Tweets.change_comment(comment)
    upload_name = "upload_#{random_string(7)}"

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:image, upload_name)
     |> assign_form(changeset)
     |> allow_upload(upload_name, accept: ~w(.jpg .jpeg .png), max_entries: 1, auto_upload: true)}
  end

  @impl true
  def handle_event("validate", %{"comment" => comment_params}, socket) do
    image_name = if image_added?(socket), do: socket.assigns.image, else: nil
    Map.put(comment_params, "image", image_name)

    changeset =
      socket.assigns.comment
      |> Tweets.change_comment(comment_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"comment" => comment_params}, socket) do
    save_comment(socket, socket.assigns.action, comment_params)
  end

  def handle_event("cancel-upload", %{}, socket) do
    socket =
      if socket.assigns.uploads != nil do
        Enum.reduce(socket.assigns.uploads[socket.assigns.image].entries, socket, fn entry, acc ->
          cancel_upload(acc, socket.assigns.image, entry.ref)
        end)
      else
        socket
      end

    {:noreply, socket}
  end

  defp save_comment(socket, :edit, comment_params) do
    case Tweets.update_comment(socket.assigns.comment, comment_params) do
      {:ok, comment} ->
        notify_parent({:saved, comment})

        {:noreply,
         socket
         |> put_flash(:info, "Comment updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_comment(socket, :new, comment_params) do
    comment_params = maybe_add_uploaded_image(comment_params, socket)

    assoc_params =
      %{}
      |> Map.put("comment_id", socket.assigns[:reply_to])
      |> Map.put("user_id", socket.assigns.user_id)
      |> Map.put("tweet_id", socket.assigns.tweet_id)

    case Tweets.create_comment(comment_params, assoc_params) do
      {:ok, _comment} ->
        {:noreply,
         socket
         |> put_flash(:info, "Comment created successfully")
         |> push_navigate(to: "/tweets/#{socket.assigns.tweet_id}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp maybe_add_uploaded_image(comment_params, socket) do
    response =
      consume_uploaded_entries(socket, socket.assigns.image, fn %{path: path}, entry ->
        if entry.cancelled? == false do
          dest =
            Path.join([:code.priv_dir(:twit_clone), "static", "uploads", Path.basename(path)])

          File.cp!(path, dest)
          {:ok, ~p"/uploads/#{Path.basename(dest)}"}
        end
      end)

    Map.put(comment_params, "image", List.first(response))
  end

  defp image_added?(socket) do
    image_name = socket.assigns.image
    socket.assigns.uploads[image_name].entries != []
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
