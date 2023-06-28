defmodule TwitCloneWeb.TweetLiveTest do
  use TwitCloneWeb.ConnCase

  import Phoenix.LiveViewTest
  import TwitClone.TweetsFixtures
  alias TwitClone.AccountsFixtures
  alias TwitClone.Repo
  alias TwitClone.Tweets.Tweet

  @create_attrs %{body: "some body"}
  @update_attrs %{body: "some updated body"}
  @invalid_attrs %{body: nil}

  setup do
    on_exit(fn -> empty_uploads_folder() end)
  end

  defp create_tweet(_) do
    user = AccountsFixtures.user_fixture()
    user_id = user.id
    tweet = tweet_fixture(%{}, user_id)
    %{tweet: tweet, user_id: user_id, user: user}
  end

  describe "when user is not logged in, Index" do
    setup [:create_tweet]

    test "lists all tweets", %{conn: conn, tweet: tweet} do
      {:ok, _view, html} =
        conn
        |> live(~p"/tweets")

      assert html =~ "Listing Tweets"
      assert html =~ tweet.body
    end

    test "new action redirects to log in", %{conn: conn} do
      {:error, {:redirect, %{flash: _error, to: path}}} =
        conn
        |> live(~p"/tweets/new")

      assert path == ~p"/users/log_in"
    end

    test "edit action redirects to log in", %{conn: conn, tweet: tweet} do
      {:error, {:redirect, %{flash: _error, to: path}}} = live(conn, ~p"/tweets/#{tweet.id}/edit")

      assert path == ~p"/users/log_in"
    end

    test "handle_event 'delete' does not delete tweet", %{conn: conn, tweet: tweet} do
      {:ok, view, html} = live(conn, ~p"/tweets")
      assert html =~ tweet.body

      assert render_hook(view, :delete, %{"id" => tweet.id}) =~ tweet.body
      assert tweet == Repo.get!(Tweet, tweet.id)
    end
  end

  describe "when user is logged in, Index" do
    setup [:create_tweet]

    test "lists all tweets", %{conn: conn, tweet: tweet, user: user} do
      {:ok, _index_live, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/tweets")

      assert html =~ "Listing Tweets"
      assert html =~ tweet.body
    end

    test "new action renders new form and creates new tweet on submitting", %{
      conn: conn,
      user: user
    } do
      {:ok, index_live, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/tweets")

      assert index_live |> element("a", "New Tweet") |> render_click() =~
               "New Tweet"

      assert_patch(index_live, ~p"/tweets/new")

      assert index_live
             |> form("#tweet-form", tweet: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#tweet-form", tweet: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/tweets")

      [_first, last] = Repo.all(Tweet)

      html = render(index_live)
      assert html =~ "Tweet created successfully"
      assert html =~ "some body"
      assert last.body == @create_attrs.body
    end

    test "edit action renders edit form and updates tweet after submitting", %{
      conn: conn,
      tweet: tweet,
      user: user
    } do
      {:ok, index_live, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/tweets")

      assert index_live |> element("#tweets-#{tweet.id} a", "Edit") |> render_click() =~
               "Edit Tweet"

      assert_patch(index_live, ~p"/tweets/#{tweet}/edit")

      assert index_live
             |> form("#tweet-form", tweet: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#tweet-form", tweet: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/tweets")

      [tweet] = Repo.all(Tweet)

      html = render(index_live)
      assert html =~ "Tweet updated successfully"
      assert html =~ "some updated body"
      assert tweet.body == @update_attrs.body
    end

    test "handle_event 'delete' removes tweet from view and db", %{
      conn: conn,
      tweet: tweet,
      user: user
    } do
      {:ok, view, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/tweets")

      assert html =~ tweet.body
      refute render_hook(view, :delete, %{"id" => tweet.id}) =~ tweet.body
      assert_raise Ecto.NoResultsError, fn -> Repo.get!(Tweet, tweet.id) end
    end
  end

  describe "when user is not logged in Show" do
    setup [:create_tweet]

    test "displays tweet", %{conn: conn, tweet: tweet} do
      {:ok, _show_live, html} = live(conn, ~p"/tweets/#{tweet}")

      assert html =~ "Show Tweet"
      assert html =~ tweet.body
    end
  end

  describe "when user is logged in Show" do
    setup [:create_tweet]

    test "displays tweet", %{conn: conn, tweet: tweet, user: user} do
      {:ok, _show_live, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/tweets/#{tweet}")

      assert html =~ "Show Tweet"
      assert html =~ tweet.body
    end
  end

  describe "with action new FormComponent" do
    setup [:create_tweet]

    test "uploads a file", %{conn: conn, user: user} do
      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/tweets/new")

      file_name = "test_image.jpg"

      file =
        file_input(view, "#tweet-form", :image, [
          %{
            last_modified: 1_594_171_879_000,
            name: file_name,
            content: File.read!("test/support/test_image.jpg"),
            type: "image/jpeg"
          }
        ])

      assert render_upload(file, "test_image.jpg") =~ "100%"
    end

    test "removes file from upload after cancel-upload event", %{conn: conn, user: user} do
      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/tweets/new")

      file_name = "test_image.jpg"

      file =
        file_input(view, "#tweet-form", :image, [
          %{
            last_modified: 1_594_171_879_000,
            name: file_name,
            content: File.read!("test/support/test_image.jpg"),
            type: "image/jpeg"
          }
        ])

      assert render_upload(file, "test_image.jpg") =~ "100%"
      assert view |> element("progress") |> has_element?()
      assert view |> element(".image-preview") |> has_element?()

      view |> element("#cancel-upload") |> render_click()

      refute view |> element("progress") |> has_element?()
      refute view |> element(".image-preview") |> has_element?()
    end

    test "saves a file in a storage after submitting", %{conn: conn, user: user} do
      empty_uploads_folder()

      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/tweets/new")

      file_name = "test_image.jpg"

      file =
        file_input(view, "#tweet-form", :image, [
          %{
            last_modified: 1_594_171_879_000,
            name: file_name,
            content: File.read!("test/support/test_image.jpg"),
            type: "image/jpeg"
          }
        ])

      assert render_upload(file, "test_image.jpg") =~ "100%"

      assert view
             |> form("#tweet-form", tweet: %{body: "tweet body"})
             |> render_submit()

      [_first, tweet] = Repo.all(Tweet)

      assert tweet.image =~ "/uploads/"
      assert image_exists?(tweet.image) == true
    end

    test "does not save a file in a storage after submitting with invalid params", %{
      conn: conn,
      user: user
    } do
      empty_uploads_folder()

      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/tweets/new")

      file_name = "test_image.jpg"

      file =
        file_input(view, "#tweet-form", :image, [
          %{
            last_modified: 1_594_171_879_000,
            name: file_name,
            content: File.read!("test/support/test_image.jpg"),
            type: "image/jpeg"
          }
        ])

      count_before = uploaded_images_count()

      assert render_upload(file, "test_image.jpg") =~ "100%"

      assert view
             |> form("#tweet-form", tweet: %{body: ""})
             |> render_submit()

      assert uploaded_images_count() == count_before
    end
  end

  describe "with action :edit FormComponent" do
    setup [:create_tweet]

    test "uploads a file", %{conn: conn, user: user, tweet: tweet} do
      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/tweets/#{tweet.id}/edit")

      file_name = "test_image.jpg"

      file =
        file_input(view, "#tweet-form", :image, [
          %{
            last_modified: 1_594_171_879_000,
            name: file_name,
            content: File.read!("test/support/test_image.jpg"),
            type: "image/jpeg"
          }
        ])

      assert render_upload(file, "test_image.jpg") =~ "100%"
    end

    test "restores tweet actual image after cancel-upload event", %{
      conn: conn,
      user: user,
      tweet: tweet
    } do
      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/tweets/#{tweet.id}/edit")

      file_name = "test_image.jpg"

      file =
        file_input(view, "#tweet-form", :image, [
          %{
            last_modified: 1_594_171_879_000,
            name: file_name,
            content: File.read!("test/support/test_image.jpg"),
            type: "image/jpeg"
          }
        ])

      assert render_upload(file, "test_image.jpg") =~ "100%"
      assert view |> element("progress") |> has_element?()
      assert view |> element(".image-preview") |> has_element?()

      view |> element("#cancel-upload") |> render_click()

      refute view |> element("progress") |> has_element?()
      refute view |> element(".image-preview") |> has_element?()
      assert view |> element(".tweet-image") |> has_element?()
    end

    test "removes file from upload after cancel-upload event", %{
      conn: conn,
      user: user,
      tweet: tweet
    } do
      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/tweets/#{tweet.id}/edit")

      file_name = "test_image.jpg"

      file =
        file_input(view, "#tweet-form", :image, [
          %{
            last_modified: 1_594_171_879_000,
            name: file_name,
            content: File.read!("test/support/test_image.jpg"),
            type: "image/jpeg"
          }
        ])

      assert render_upload(file, "test_image.jpg") =~ "100%"
      assert view |> element("progress") |> has_element?()
      assert view |> element(".image-preview") |> has_element?()

      view |> element("#cancel-upload") |> render_click()

      refute view |> element("progress") |> has_element?()
      refute view |> element(".image-preview") |> has_element?()
    end

    test "saves a file in a storage after submitting", %{conn: conn, user: user, tweet: tweet} do
      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/tweets/#{tweet.id}/edit")

      file_name = "test_image.jpg"

      file =
        file_input(view, "#tweet-form", :image, [
          %{
            last_modified: 1_594_171_879_000,
            name: file_name,
            content: File.read!("test/support/test_image.jpg"),
            type: "image/jpeg"
          }
        ])

      assert render_upload(file, "test_image.jpg") =~ "100%"

      assert view
             |> form("#tweet-form", tweet: %{body: "updated body"})
             |> render_submit()

      [updated_tweet] = Repo.all(Tweet)

      assert updated_tweet.image =~ "/uploads/"
      assert image_exists?(updated_tweet.image) == true
    end

    test "does not save a file in a storage after submitting with invalid params", %{
      conn: conn,
      user: user,
      tweet: tweet
    } do
      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/tweets/#{tweet.id}/edit")

      file_name = "test_image.jpg"

      file =
        file_input(view, "#tweet-form", :image, [
          %{
            last_modified: 1_594_171_879_000,
            name: file_name,
            content: File.read!("test/support/test_image.jpg"),
            type: "image/jpeg"
          }
        ])

      count_before = uploaded_images_count()

      assert render_upload(file, "test_image.jpg") =~ "100%"

      assert view
             |> form("#tweet-form", tweet: %{body: ""})
             |> render_submit()

      assert uploaded_images_count() == count_before
    end

    test "shows error message when uploaded file has invalid format", %{
      conn: conn,
      user: user,
      tweet: tweet
    } do
      empty_uploads_folder()

      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/tweets/#{tweet.id}/edit")

      file_name = "test_image.gif"

      file =
        file_input(view, "#tweet-form", :image, [
          %{
            last_modified: 1_594_171_879_000,
            name: file_name,
            content: File.read!("test/support/test_image.gif"),
            type: "image/gif"
          }
        ])

      assert {:error, [[_, :not_accepted]]} = render_upload(file, "test_image.gif")

      html = render(view)
      assert html =~ "You have selected an unacceptable file type"
    end

    test "shows error message when trying to upload more than 1 file", %{
      conn: conn,
      user: user,
      tweet: tweet
    } do
      empty_uploads_folder()

      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/tweets/#{tweet.id}/edit")

      file_name = "test_image.jpg"

      file =
        file_input(view, "#tweet-form", :image, [
          %{
            last_modified: 1_594_171_879_000,
            name: file_name,
            content: File.read!("test/support/test_image.jpg"),
            type: "image/jpeg"
          },
          %{
            last_modified: 1_594_171_879_000,
            name: file_name,
            content: File.read!("test/support/test_image.jpg"),
            type: "image/jpeg"
          }
        ])

      assert {:error, [[_, :too_many_files]]} = render_upload(file, "test_image.jpg")

      html = render(view)
      assert html =~ "You have selected too many files"
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

  defp empty_uploads_folder() do
    path =
      Path.join([
        :code.priv_dir(:twit_clone),
        "static",
        "uploads/"
      ])

    File.rm_rf(path)
    File.mkdir(path)
  end

  defp uploaded_images_count() do
    upload_folder =
      Path.join([
        :code.priv_dir(:twit_clone),
        "static",
        "uploads"
      ])

    {:ok, result} = File.ls(upload_folder)
    length(result)
  end
end
