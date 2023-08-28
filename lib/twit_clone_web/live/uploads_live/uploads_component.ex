defmodule TwitCloneWeb.TweetLive.UploadsComponent do
  use TwitCloneWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div class="upload-container flex flex-col items-center">
      <%= for entry <- @uploads.image.entries do %>
        <div class="image-preview">
          <.live_img_preview entry={entry} class={@preview_class} />
        </div>
      <% end %>
      <div class="flex flex-col mt-4 justify-center ">
        <label class="border-2 p-1 mb-1 cursor-pointer rounded-md w-full text-center">
          <.live_file_input
            phx-click="cancel-upload"
            phx-target={@myself}
            phx-value-validate="false"
            upload={@uploads.image}
            class="hidden"
          />
          <%= @input_label %>
        </label>
        <%= if @uploads.image.entries != [] do %>
          <button
            type="button"
            id="cancel-upload"
            phx-click="cancel-upload"
            phx-target={@myself}
            phx-value-validate="true"
            aria-label="cancel"
            class="border-2 p-1 rounded-md mb-1 w-full"
          >
            Cancel
          </button>
        <% end %>
      </div>
      <div
        :for={{_num, err} <- @uploads.image.errors}
        class="mt-3 flex gap-3 text-sm leading-6 text-rose-600 phx-no-feedback:hidden"
      >
        <%= error_to_string(err) %>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("cancel-upload", %{"validate" => validate}, socket) do
    socket =
      if socket.assigns.uploads != nil do
        Enum.reduce(socket.assigns.uploads.image.entries, socket, fn entry, acc ->
          cancel_upload(acc, :image, entry.ref)
        end)
      else
        socket
      end

    socket =
      case validate do
        "true" -> push_event(socket, "validate_form", %{to: socket.assigns.validate_target})
        "false" -> socket
      end

    {:noreply, socket}
  end

  def maybe_update_image(socket, params, image_name) do
    folder = get_folder_for(image_name)

    upload_response =
      consume_uploaded_entries(socket, :image, fn %{path: path}, _entry ->
        dest = Path.join([:code.priv_dir(:twit_clone), "static", folder, Path.basename(path)])
        File.cp!(path, dest)
        {:ok, "/#{folder}/#{Path.basename(dest)}"}
      end)

    with nil <- socket.assigns[:remove_image],
         nil <- List.first(upload_response) do
      params
    else
      true -> Map.put(params, "remove-image", true) |> Map.put(image_name, nil)
      image -> Map.put(params, image_name, image)
    end
  end

  @spec image_added?(struct()) :: boolean
  def image_added?(socket) do
    socket.assigns.uploads.image.entries != []
  end

  def error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
  def error_to_string(:too_many_files), do: "You have selected too many files"

  defp get_folder_for("image") do
    "uploads"
  end

  defp get_folder_for("avatar") do
    "avatars"
  end
end
