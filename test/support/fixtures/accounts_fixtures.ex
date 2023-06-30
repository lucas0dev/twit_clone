defmodule TwitClone.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `TwitClone.Accounts` context.
  """

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "hello world!"
  def unique_account_name, do: "user#{System.unique_integer()}"
  def valid_user_name, do: "user_name"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      password: valid_user_password(),
      account_name: unique_account_name(),
      name: valid_user_name()
    })
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> Map.put(:avatar, user_avatar())
      |> TwitClone.Accounts.register_user()

    user
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end

  def user_avatar() do
    image = "test/support/test_image.jpg"
    dest = Path.join([:code.priv_dir(:twit_clone), "static", "avatars", random_string()])
    File.cp!(image, dest)
    "/avatars/#{Path.basename(dest)}"
  end

  def random_string(length \\ 10) do
    :crypto.strong_rand_bytes(length) |> Base.url_encode64() |> binary_part(0, length)
  end
end
