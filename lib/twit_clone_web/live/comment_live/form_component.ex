defmodule TwitCloneWeb.CommentLive.FormComponent do
  use TwitCloneWeb, :live_component

  alias TwitClone.Tweets
  alias TwitCloneWeb.IconComponents
  alias TwitCloneWeb.TweetLive.UploadsComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-row py-4 px-2 w-full">
      <div class="flex flex-row w-full items-start">
        <img class="h-12 w-12 rounded-full" src={@avatar} />
        <.simple_form
          for={@form}
          id={"#{assign_id(@action)}-form"}
          class="ml-2 flex-1"
          phx-target={@myself}
          phx-change="validate"
          phx-submit="save"
        >
          <.input
            id={"#{assign_id(@action)}-body"}
            class="comment-body -mt-2"
            field={@form[:body]}
            type="textarea"
            maxlength="280"
            placeholder="Add a comment"
          />
          <%= if @uploads.image.entries == [] && @comment_image != nil do %>
            <img class="comment-image max-h-80 mx-auto border rounded-md" src={@comment_image} />
          <% end %>
          <div class="mx-auto">
            <.live_component
              module={UploadsComponent}
              uploads={@uploads}
              id={"upload_#{random_string(6)}"}
              validate_target="comment-body"
              image={@form[:image]}
              parent="comment"
              preview_class="max-h-80 mx-auto"
              input_label="Add image"
            />
            <%= if @comment_image != nil do %>
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
            <.button phx-disable-with="Saving..." class="right ml-auto">Send</.button>
          </:actions>
        </.simple_form>
        <%= if @hidden do %>
          <button class="ml-2 w-4" phx-click={JS.add_class("hidden", to: "#comment-form-container")}>
            <IconComponents.close />
          </button>
        <% end %>
      </div>
    </div>
    """
  end

  @impl true
  def update(%{comment: comment} = assigns, socket) do
    changeset = Tweets.change_comment(comment)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:comment_image, comment.image)
     |> assign_form(changeset)
     |> allow_upload(:image, accept: ~w(.jpg .jpeg .png), max_entries: 1, auto_upload: true)}
  end

  @impl true
  def handle_event("validate", %{"comment" => comment_params}, socket) do
    image_name = if UploadsComponent.image_added?(socket), do: "temporary_name", else: nil
    comment_params = Map.put(comment_params, "image", image_name)

    changeset =
      socket.assigns.comment
      |> Tweets.change_comment(comment_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("save", %{"comment" => comment_params}, socket) do
    save_comment(socket, socket.assigns.action, comment_params)
  end

  @impl true
  def handle_event("remove-image", _, socket) do
    socket =
      socket
      |> assign(:remove_image, true)
      |> assign(:comment_image, nil)

    {:noreply, socket}
  end

  defp save_comment(socket, :edit, comment_params) do
    user_id = socket.assigns.user_id
    comment_params = UploadsComponent.maybe_update_image(socket, comment_params, "image")

    case Tweets.update_comment(socket.assigns.comment, comment_params, user_id) do
      {:ok, _comment} ->
        {:noreply,
         socket
         |> put_flash(:info, "Comment updated successfully")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        Tweets.delete_image(comment_params["image"])
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_comment(socket, :new, comment_params) do
    comment_params = UploadsComponent.maybe_update_image(socket, comment_params, "image")

    assoc_params =
      %{}
      |> Map.put("user_id", socket.assigns.user_id)
      |> Map.put("parent_tweet_id", socket.assigns.parent_tweet_id)

    case Tweets.create_comment(comment_params, assoc_params) do
      {:ok, _comment} ->
        {:noreply,
         socket
         |> put_flash(:info, "Comment created successfully")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        Tweets.delete_image(comment_params["image"])
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp random_string(bytes_count) do
    bytes_count
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end

  defp assign_id(action) do
    case action do
      :new -> "new-comment"
      :edit -> "edit-comment"
    end
  end
end
