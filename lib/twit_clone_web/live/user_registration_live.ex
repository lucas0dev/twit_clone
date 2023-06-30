defmodule TwitCloneWeb.UserRegistrationLive do
  use TwitCloneWeb, :live_view

  import TwitCloneWeb.LiveHelpers
  alias TwitClone.Accounts
  alias TwitClone.Accounts.User

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <.header class="text-center">
        Register for an account
        <:subtitle>
          Already registered?
          <.link navigate={~p"/users/log_in"} class="font-semibold text-brand hover:underline">
            Sign in
          </.link>
          to your account now.
        </:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="registration_form"
        phx-submit="save"
        phx-change="validate"
        phx-trigger-action={@trigger_submit}
        action={~p"/users/log_in?_action=registered"}
        method="post"
      >
        <.error :if={@check_errors}>
          Oops, something went wrong! Please check the errors below.
        </.error>

        <.input field={@form[:email]} type="email" label="Email" required />
        <.input field={@form[:password]} type="password" label="Password" required />
        <.input field={@form[:account_name]} type="text" label="Account name" required />
        <.input field={@form[:name]} type="text" label="Name" required />
        <label class="block text-sm font-semibold leading-6 text-zinc-800" for="avatar">Avatar</label>
        <%= for entry <- @uploads.avatar.entries do %>
          <article>
            <div class="image-preview">
              <.live_img_preview entry={entry} />
            </div>
            <progress value={entry.progress} max="100"><%= entry.progress %>%</progress>
            <button
              type="button"
              id="cancel-upload"
              phx-click="cancel-upload"
              phx-value-ref={entry.ref}
              aria-label="cancel"
            >
              &times;
            </button>
          </article>
        <% end %>
        <.live_file_input upload={@uploads.avatar} />
        <div
          :for={{_num, err} <- @uploads.avatar.errors}
          class="mt-3 flex gap-3 text-sm leading-6 text-rose-600 phx-no-feedback:hidden"
        >
          <%= error_to_string(err) %>
        </div>
        <:actions>
          <.button phx-disable-with="Creating account..." class="w-full">Create an account</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_registration(%User{})

    socket =
      socket
      |> assign(trigger_submit: false, check_errors: false)
      |> assign_form(changeset)
      |> allow_upload(:avatar, accept: ~w(.jpg .jpeg .png), max_entries: 1, auto_upload: true)

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    upload_response =
      consume_uploaded_entries(socket, :avatar, fn %{path: path}, _entry ->
        dest = Path.join([:code.priv_dir(:twit_clone), "static", "avatars", Path.basename(path)])
        File.cp!(path, dest)
        {:ok, ~p"/avatars/#{Path.basename(dest)}"}
      end)

    image_path = List.first(upload_response)

    case Accounts.register_user(Map.put(user_params, "avatar", image_path)) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_user_confirmation_instructions(
            user,
            &url(~p"/users/confirm/#{&1}")
          )

        changeset = Accounts.change_user_registration(user)
        {:noreply, socket |> assign(trigger_submit: true) |> assign_form(changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        Accounts.delete_image(image_path)
        {:noreply, socket |> assign(check_errors: true) |> assign_form(changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_registration(%User{}, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :avatar, ref)}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")

    if changeset.valid? do
      assign(socket, form: form, check_errors: false)
    else
      assign(socket, form: form)
    end
  end
end
