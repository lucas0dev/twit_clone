defmodule TwitCloneWeb.UserSettingsLive do
  use TwitCloneWeb, :live_view

  alias TwitClone.Accounts
  alias TwitCloneWeb.TweetLive.UploadsComponent

  @default_avatar "/avatars/default_avatar.png"

  def render(assigns) do
    ~H"""
    <.header class="text-center">
      Account Settings
      <:subtitle>Manage your account email address and password settings</:subtitle>
    </.header>

    <div class="space-y-12 divide-y">
      <div>
        <.simple_form
          for={@info_form}
          id="info_form"
          phx-submit="update_user"
          phx-change="validate_info"
        >
          <label class="block text-sm font-semibold leading-6 text-zinc-800" for="avatar">
            Avatar
          </label>
          <div class="flex flex-col items-center justify-center">
            <%= if @uploads.image.entries == [] && @avatar != nil do %>
              <img class="avatar h-32 w-32 rounded-full mb-5" src={@avatar} />
            <% end %>
            <div>
              <.live_component
                module={UploadsComponent}
                uploads={@uploads}
                image={@avatar}
                id="avatar_upload"
                validate_target="tweet-body"
                preview_class="avatar h-32 w-32 rounded-full mb-5"
                input_label="Add new avatar"
              />
              <%= if !default_avatar?(@avatar) do %>
                <button
                  class="border-2 p-1 rounded-md w-full"
                  type="button"
                  id="remove-avatar"
                  phx-click={
                    JS.push("remove-image")
                    |> JS.push("cancel-upload",
                      value: %{"validate" => "false"},
                      target: ".upload-container"
                    )
                  }
                  aria-label="remove avatar"
                  class=""
                >
                  Remove avatar
                </button>
              <% end %>
            </div>
          </div>
          <.input field={@info_form[:name]} type="text" label="Name" required />
          <:actions>
            <.button phx-disable-with="Changing...">Save changes</.button>
          </:actions>
        </.simple_form>
      </div>
      <div>
        <.simple_form
          for={@email_form}
          id="email_form"
          phx-submit="update_email"
          phx-change="validate_email"
        >
          <.input field={@email_form[:email]} type="email" label="Email" required />
          <.input
            field={@email_form[:current_password]}
            name="current_password"
            id="current_password_for_email"
            type="password"
            label="Current password"
            value={@email_form_current_password}
            required
          />
          <:actions>
            <.button phx-disable-with="Changing...">Change Email</.button>
          </:actions>
        </.simple_form>
      </div>
      <div>
        <.simple_form
          for={@password_form}
          id="password_form"
          action={~p"/users/log_in?_action=password_updated"}
          method="post"
          phx-change="validate_password"
          phx-submit="update_password"
          phx-trigger-action={@trigger_submit}
        >
          <.input
            field={@password_form[:email]}
            type="hidden"
            id="hidden_user_email"
            value={@current_email}
          />
          <.input field={@password_form[:password]} type="password" label="New password" required />
          <.input
            field={@password_form[:password_confirmation]}
            type="password"
            label="Confirm new password"
          />
          <.input
            field={@password_form[:current_password]}
            name="current_password"
            type="password"
            label="Current password"
            id="current_password_for_password"
            value={@current_password}
            required
          />
          <:actions>
            <.button phx-disable-with="Changing...">Change Password</.button>
          </:actions>
        </.simple_form>
      </div>
    </div>
    """
  end

  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_user, token) do
        :ok ->
          put_flash(socket, :info, "Email changed successfully.")

        :error ->
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/users/settings")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    email_changeset = Accounts.change_user_email(user)
    password_changeset = Accounts.change_user_password(user)
    info_changeset = Accounts.change_user_info(user)

    socket =
      socket
      |> assign(:avatar, user.avatar)
      |> assign(:current_password, nil)
      |> assign(:email_form_current_password, nil)
      |> assign(:current_email, user.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:info_form, to_form(info_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:trigger_submit, false)
      |> allow_upload(:image, accept: ~w(.jpg .jpeg .png), max_entries: 1, auto_upload: true)

    {:ok, socket}
  end

  def handle_event("validate_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    email_form =
      socket.assigns.current_user
      |> Accounts.change_user_email(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form, email_form_current_password: password)}
  end

  def handle_event("validate_info", params, socket) do
    %{"user" => user_params} = params

    info_form =
      socket.assigns.current_user
      |> Accounts.change_user_info(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, info_form: info_form)}
  end

  def handle_event("update_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.apply_user_email(user, password, user_params) do
      {:ok, applied_user} ->
        Accounts.deliver_user_update_email_instructions(
          applied_user,
          user.email,
          &url(~p"/users/settings/confirm_email/#{&1}")
        )

        info = "A link to confirm your email change has been sent to the new address."
        {:noreply, socket |> put_flash(:info, info) |> assign(email_form_current_password: nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, :email_form, to_form(Map.put(changeset, :action, :insert)))}
    end
  end

  def handle_event("update_user", params, socket) do
    %{"user" => user_params} = params
    user_id = socket.assigns.current_user.id
    user = Accounts.get_user!(user_id)
    user_params = UploadsComponent.maybe_update_image(socket, user_params, "avatar")

    case Accounts.update_user_info(user, user_params) do
      {:ok, updated_user} ->
        info = "Your profile has been updated."

        socket =
          socket
          |> assign(:remove_image, nil)
          |> assign(:avatar, updated_user.avatar)
          |> put_flash(:info, info)

        {:noreply, socket}

      {:error, changeset} ->
        Accounts.delete_avatar(user_params["avatar"])

        socket =
          socket
          |> assign(:remove_image, nil)

        {:noreply, assign(socket, :info_form, to_form(Map.put(changeset, :action, :insert)))}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    password_form =
      socket.assigns.current_user
      |> Accounts.change_user_password(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form, current_password: password)}
  end

  def handle_event("update_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        password_form =
          user
          |> Accounts.change_user_password(user_params)
          |> to_form()

        {:noreply, assign(socket, trigger_submit: true, password_form: password_form)}

      {:error, changeset} ->
        {:noreply, assign(socket, password_form: to_form(changeset))}
    end
  end

  def handle_event("remove-image", _, socket) do
    socket =
      socket
      |> assign(:remove_image, true)
      |> assign(:avatar, @default_avatar)

    {:noreply, socket}
  end

  def default_avatar?(avatar) do
    avatar == @default_avatar
  end
end
