defmodule TwitCloneWeb.UserSettingsLiveTest do
  use TwitCloneWeb.ConnCase

  alias TwitClone.Accounts
  import Phoenix.LiveViewTest
  import Phoenix.HTML
  import TwitClone.AccountsFixtures

  describe "Settings page" do
    test "renders settings page", %{conn: conn} do
      {:ok, _lv, html} =
        conn
        |> log_in_user(user_fixture())
        |> live(~p"/users/settings")

      assert html =~ "Change Email"
      assert html =~ "Change Password"
      assert html =~ "Save changes"
    end

    test "redirects if user is not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/users/settings")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log_in"
      assert %{"error" => "You must log in to access this page."} = flash
    end
  end

  describe "update email form" do
    setup %{conn: conn} do
      password = valid_user_password()
      user = user_fixture(%{password: password})
      %{conn: log_in_user(conn, user), user: user, password: password}
    end

    test "updates the user email", %{conn: conn, password: password, user: user} do
      new_email = unique_user_email()

      {:ok, lv, _html} = live(conn, ~p"/users/settings")

      result =
        lv
        |> form("#email_form", %{
          "current_password" => password,
          "user" => %{"email" => new_email}
        })
        |> render_submit()

      assert result =~ "A link to confirm your email"
      assert Accounts.get_user_by_email(user.email)
    end

    test "renders errors with invalid data (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings")

      result =
        lv
        |> element("#email_form")
        |> render_change(%{
          "action" => "update_email",
          "current_password" => "invalid",
          "user" => %{"email" => "with spaces"}
        })

      assert result =~ "Change Email"
      assert result =~ "must have the @ sign and no spaces"
    end

    test "renders errors with invalid data (phx-submit)", %{conn: conn, user: user} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings")

      result =
        lv
        |> form("#email_form", %{
          "current_password" => "invalid",
          "user" => %{"email" => user.email}
        })
        |> render_submit()

      assert result =~ "Change Email"
      assert result =~ "did not change"
      assert result =~ "is not valid"
    end
  end

  describe "update password form" do
    setup %{conn: conn} do
      password = valid_user_password()
      user = user_fixture(%{password: password})
      %{conn: log_in_user(conn, user), user: user, password: password}
    end

    test "updates the user password", %{conn: conn, user: user, password: password} do
      new_password = valid_user_password()

      {:ok, lv, _html} = live(conn, ~p"/users/settings")

      form =
        form(lv, "#password_form", %{
          "current_password" => password,
          "user" => %{
            "email" => user.email,
            "password" => new_password,
            "password_confirmation" => new_password
          }
        })

      render_submit(form)

      new_password_conn = follow_trigger_action(form, conn)

      assert redirected_to(new_password_conn) == ~p"/users/settings"

      assert get_session(new_password_conn, :user_token) != get_session(conn, :user_token)

      assert Phoenix.Flash.get(new_password_conn.assigns.flash, :info) =~
               "Password updated successfully"

      assert Accounts.get_user_by_email_and_password(user.email, new_password)
    end

    test "renders errors with invalid data (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings")

      result =
        lv
        |> element("#password_form")
        |> render_change(%{
          "current_password" => "invalid",
          "user" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      assert result =~ "Change Password"
      assert result =~ "should be at least 12 character(s)"
      assert result =~ "does not match password"
    end

    test "renders errors with invalid data (phx-submit)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings")

      result =
        lv
        |> form("#password_form", %{
          "current_password" => "invalid",
          "user" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })
        |> render_submit()

      assert result =~ "Change Password"
      assert result =~ "should be at least 12 character(s)"
      assert result =~ "does not match password"
      assert result =~ "is not valid"
    end
  end

  describe "confirm email" do
    setup %{conn: conn} do
      user = user_fixture()
      email = unique_user_email()

      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_update_email_instructions(%{user | email: email}, user.email, url)
        end)

      %{conn: log_in_user(conn, user), token: token, email: email, user: user}
    end

    test "updates the user email once", %{conn: conn, user: user, token: token, email: email} do
      {:error, redirect} = live(conn, ~p"/users/settings/confirm_email/#{token}")

      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/settings"
      assert %{"info" => message} = flash
      assert message == "Email changed successfully."
      refute Accounts.get_user_by_email(user.email)
      assert Accounts.get_user_by_email(email)

      # use confirm token again
      {:error, redirect} = live(conn, ~p"/users/settings/confirm_email/#{token}")
      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/settings"
      assert %{"error" => message} = flash
      assert message == "Email change link is invalid or it has expired."
    end

    test "does not update email with invalid token", %{conn: conn, user: user} do
      {:error, redirect} = live(conn, ~p"/users/settings/confirm_email/oops")
      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/settings"
      assert %{"error" => message} = flash
      assert message == "Email change link is invalid or it has expired."
      assert Accounts.get_user_by_email(user.email)
    end

    test "redirects if user is not logged in", %{token: token} do
      conn = build_conn()
      {:error, redirect} = live(conn, ~p"/users/settings/confirm_email/#{token}")
      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log_in"
      assert %{"error" => message} = flash
      assert message == "You must log in to access this page."
    end
  end

  describe "update info form" do
    setup %{conn: conn} do
      password = valid_user_password()
      user = user_fixture(%{password: password})
      %{conn: log_in_user(conn, user), user: user, password: password}
    end

    test "updates the user name", %{conn: conn, user: user} do
      new_name = valid_user_name()
      user_id = user.id
      {:ok, lv, _html} = live(conn, ~p"/users/settings")

      result =
        lv
        |> form("#info_form", %{
          "user" => %{"name" => new_name}
        })
        |> render_submit()

      assert result =~ "Your profile has been updated."
      assert Accounts.get_user!(user_id).name == new_name
    end

    test "updates the user avatar", %{conn: conn, user: user} do
      old_avatar = user.avatar
      new_name = valid_user_name()
      user_id = user.id
      {:ok, lv, _html} = live(conn, ~p"/users/settings")

      file_name = "test_image.jpg"

      file =
        file_input(lv, "#info_form", :image, [
          %{
            last_modified: 1_594_171_879_000,
            name: file_name,
            content: File.read!("test/support/test_image.jpg"),
            type: "image/jpeg"
          }
        ])

      render_upload(file, "test_image.jpg")

      assert lv
             |> form("#info_form", user: %{name: new_name})
             |> render_submit()

      user = Accounts.get_user!(user_id)

      assert user.name =~ new_name
      assert user.avatar =~ "/avatars/"
      assert user.avatar != old_avatar
      assert image_exists?(user.avatar) == true
    end

    test "renders errors without name (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings")

      result =
        lv
        |> element("#info_form")
        |> render_change(%{
          "user" => %{"name" => ""}
        })

      assert result =~ "Save changes"
      assert result =~ "can't be blank" |> html_escape() |> safe_to_string()
    end

    test "when providing nil name renders error and does not update user", %{
      conn: conn,
      user: user
    } do
      user_id = user.id
      {:ok, lv, _html} = live(conn, ~p"/users/settings")

      result =
        lv
        |> form("#info_form", %{
          "user" => %{"name" => nil}
        })
        |> render_submit()

      assert result =~ "can't be blank" |> html_escape() |> safe_to_string()
      assert Accounts.get_user!(user_id).name == user.name
    end

    test "does not update user avatar when cancel is clicked", %{conn: conn, user: user} do
      new_name = valid_user_name()
      old_avatar = user.avatar
      user_id = user.id
      {:ok, lv, _html} = live(conn, ~p"/users/settings")

      file_name = "test_image.jpg"

      file =
        file_input(lv, "#info_form", :image, [
          %{
            last_modified: 1_594_171_879_000,
            name: file_name,
            content: File.read!("test/support/test_image.jpg"),
            type: "image/jpeg"
          }
        ])

      render_upload(file, "test_image.jpg")

      assert lv |> element("button", "Cancel") |> render_click()

      result =
        lv
        |> form("#info_form", user: %{name: new_name})
        |> render_submit()

      user = Accounts.get_user!(user_id)

      assert result =~ "Your profile has been updated."
      assert user.avatar =~ "/avatars/"
      assert user.avatar == old_avatar
      assert image_exists?(user.avatar) == true
    end

    test "removes user avatar when remove avatar is clicked", %{conn: conn, user: user} do
      new_name = valid_user_name()
      old_avatar = user.avatar
      user_id = user.id
      {:ok, lv, _html} = live(conn, ~p"/users/settings")

      assert lv |> element("button", "Remove avatar") |> render_click()

      result =
        lv
        |> form("#info_form", user: %{name: new_name})
        |> render_submit()

      user = Accounts.get_user!(user_id)

      assert result =~ "Your profile has been updated."
      assert user.avatar =~ "/avatars/"
      assert user.avatar != old_avatar
      assert image_exists?(old_avatar) == false
    end
  end

  defp image_exists?(image_path) do
    full_path =
      Path.join([
        :code.priv_dir(:twit_clone),
        "static",
        "/#{image_path}"
      ])

    File.exists?(full_path)
  end
end
