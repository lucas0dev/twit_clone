defmodule TwitCloneWeb.UserRegistrationLive do
  use TwitCloneWeb, :live_view

  alias TwitClone.Accounts
  alias TwitClone.Accounts.User
  alias TwitCloneWeb.TweetLive.UploadsComponent

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
        <%= if @uploads.image.entries == [] do %>
          <img class="avatar mx-auto h-32 w-32 rounded-full mb-5" src={default_avatar()} />
        <% end %>
        <.live_component
          module={UploadsComponent}
          uploads={@uploads}
          image={nil}
          validate_target={nil}
          id="avatar_upload"
          preview_class="avatar h-32 w-32 rounded-full mb-5"
          input_label="Add avatar"
        />
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
      |> allow_upload(:image, accept: ~w(.jpg .jpeg .png), max_entries: 1, auto_upload: true)

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    user_params = UploadsComponent.maybe_update_image(socket, user_params, "avatar")

    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_user_confirmation_instructions(
            user,
            &url(~p"/users/confirm/#{&1}")
          )

        changeset = Accounts.change_user_registration(user)
        {:noreply, socket |> assign(trigger_submit: true) |> assign_form(changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        Accounts.delete_avatar(user_params["avatar"])
        {:noreply, socket |> assign(check_errors: true) |> assign_form(changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_registration(%User{}, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")

    if changeset.valid? do
      assign(socket, form: form, check_errors: false)
    else
      assign(socket, form: form)
    end
  end

  defp default_avatar do
    "/avatars/default_avatar.png"
  end
end
