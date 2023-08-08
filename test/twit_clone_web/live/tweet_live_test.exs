defmodule TwitCloneWeb.TweetLiveTest do
  use TwitCloneWeb.ConnCase

  import Phoenix.LiveViewTest
  import TwitClone.TweetsFixtures
  alias TwitClone.AccountsFixtures
  alias TwitClone.Repo
  alias TwitClone.Tweets.Tweet
  alias Phoenix.LiveView

  @create_attrs %{body: "some body"}
  @update_attrs %{body: "some updated body"}
  @invalid_attrs %{body: nil}

  defp create_tweet(_) do
    user = AccountsFixtures.user_fixture()
    user_id = user.id
    tweet = tweet_fixture(%{}, user_id)
    %{tweet: tweet, user_id: user_id, user: user}
  end

  describe "Index" do
    setup [:create_tweet]

    test "redirects to /tweets/id when clicked on tweet", %{conn: conn, tweet: tweet} do
      {:ok, lv, _html} =
        conn
        |> live(~p"/")

      {:error, {:live_redirect, %{to: path}}} = lv |> element("div.tweet") |> render_click()

      assert path =~ "/tweets/#{tweet.id}"
    end
  end

  describe "Index, when user is not logged in" do
    setup [:create_tweet]

    test "lists all tweets", %{conn: conn, tweet: tweet} do
      {:ok, _view, html} =
        conn
        |> live(~p"/")

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

    test "new comment event redirects to log in", %{conn: conn, tweet: tweet} do
      {:ok, lv, html} = live(conn, ~p"/")
      assert html =~ tweet.body

      assert lv |> element("#tweets-#{tweet.id}") |> has_element? == true

      {:error, {:redirect, %{to: path}}} = lv |> element("button.new-comment") |> render_click()

      assert path =~ "/users/log_in"
    end

    test "delete button is absent", %{conn: conn, tweet: tweet} do
      {:ok, lv, html} = live(conn, ~p"/")
      assert html =~ tweet.body

      assert lv |> element("#tweets-#{tweet.id}") |> has_element? == true

      assert lv |> element("#tweets-#{tweet.id} a", "Delete") |> has_element? == false
    end
  end

  describe "Index, when user is logged in" do
    setup [:create_tweet]

    test "lists all tweets", %{conn: conn, tweet: tweet, user: user} do
      {:ok, _index_live, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/")

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
        |> live(~p"/")

      assert index_live |> element("a", "New Tweet") |> render_click() =~
               "New Tweet"

      assert_patch(index_live, ~p"/tweets/new")

      assert index_live
             |> form("#tweet-form", tweet: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#tweet-form", tweet: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/")

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
        |> live(~p"/")

      assert index_live |> element("#tweets-#{tweet.id} a", "Edit") |> render_click() =~
               "Edit Tweet"

      assert_patch(index_live, ~p"/tweets/#{tweet}/edit")

      assert index_live
             |> form("#tweet-form", tweet: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#tweet-form", tweet: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/")

      [tweet] = Repo.all(Tweet)

      html = render(index_live)
      assert html =~ "Tweet updated successfully"
      assert html =~ "some updated body"
      assert tweet.body == @update_attrs.body
    end

    test "clicking on delete button deletes the tweet if user is its owner", %{
      conn: conn,
      tweet: tweet,
      user: user
    } do
      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/")

      assert lv |> element("#tweets-#{tweet.id}") |> has_element? == true

      lv |> element("#tweets-#{tweet.id} a", "Delete") |> render_click()

      assert lv |> element("#tweets-#{tweet.id}") |> has_element? == false
      assert_raise Ecto.NoResultsError, fn -> Repo.get!(Tweet, tweet.id) end
    end

    test " delete button is absent if user is not tweets owner", %{
      conn: conn,
      user: user
    } do
      another_tweet = tweet_fixture()

      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/")

      assert lv |> element("#tweets-#{another_tweet.id}") |> has_element? == true
      assert lv |> element("#tweets-#{another_tweet.id} a", "Delete") |> has_element? == false
    end

    test "opens new comment modal when clicked on new-comment button", %{
      conn: conn,
      user: user
    } do
      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/")

      assert lv |> element("div#comment-modal-container") |> has_element? == false

      lv |> element("button.new-comment") |> render_click()

      assert lv |> element("div#comment-modal-container") |> has_element? == true
    end
  end

  describe "Show, when user is not logged in" do
    setup [:create_tweet]

    test "displays tweet", %{conn: conn, tweet: tweet} do
      {:ok, _show_live, html} = live(conn, ~p"/tweets/#{tweet}")

      assert html =~ "Show Tweet"
      assert html =~ tweet.body
    end
  end

  describe "Show, when user is logged in" do
    setup [:create_tweet]

    test "displays tweet", %{conn: conn, tweet: tweet, user: user} do
      {:ok, _show_live, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/tweets/#{tweet}")

      assert html =~ "Show Tweet"
      assert html =~ tweet.body
    end

    test "edit action updates tweet after submitting", %{
      conn: conn,
      tweet: tweet,
      user: user
    } do
      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/tweets/#{tweet}")

      assert lv
             |> form("#tweet-form", tweet: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert lv
             |> form("#tweet-form", tweet: @update_attrs)
             |> render_submit()

      flash = assert_redirected(lv, ~p"/tweets/#{tweet}")
      assert flash["info"] == "Tweet updated successfully"

      [tweet] = Repo.all(Tweet)

      assert tweet.body == @update_attrs.body
    end

    test "clicking on delete button deletes the tweet if user is its owner", %{
      conn: conn,
      tweet: tweet,
      user: user
    } do
      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/tweets/#{tweet}")

      assert lv |> element("#actions-#{tweet.id}") |> has_element? == true

      lv |> element("#actions-#{tweet.id} a", "Delete") |> render_click()

      flash = assert_redirected(lv, ~p"/")
      assert flash["info"] == "Tweet deleted"

      assert_raise Ecto.NoResultsError, fn -> Repo.get!(Tweet, tweet.id) end
    end

    test " delete button is absent if user is not tweets owner", %{
      conn: conn,
      user: user
    } do
      another_tweet = tweet_fixture()

      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/tweets/#{another_tweet}")

      assert lv |> element("#actions-#{another_tweet.id} a", "Delete") |> has_element? == false
    end
  end

  describe "FormComponent with action new " do
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
      delete_images()

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
      delete_images()

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

  describe "FormComponent with action :edit" do
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
             |> form("#tweet-form", tweet: %{"body" => ""})
             |> render_submit()

      assert uploaded_images_count() == count_before
    end

    test "shows error message when uploaded file has invalid format", %{
      conn: conn,
      user: user,
      tweet: tweet
    } do
      delete_images()

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
      delete_images()

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

  describe "ActionsComponent when current_user is the tweet owner" do
    setup [:create_tweet]

    setup(assigns) do
      socket = %LiveView.Socket{
        endpoint: TwitCloneWeb.Endpoint,
        assigns: %{
          __changed__: %{},
          flash: %{},
          current_user: assigns.user,
          user_id: assigns.user.id,
          source: :index,
          patch: "/"
        }
      }

      {:noreply, response_socket} =
        TwitCloneWeb.TweetLive.ActionsComponent.handle_event(
          "delete",
          %{"id" => assigns.tweet.id},
          socket
        )

      %{socket: socket, response_socket: response_socket}
    end

    test "handle_event 'delete' deletes tweet", %{
      tweet: tweet
    } do
      assert_raise Ecto.NoResultsError, fn -> Repo.get!(Tweet, tweet.id) end
    end

    test "handle_event 'delete' pushes patch to '/' and shows info flash", %{
      response_socket: response_socket
    } do
      assert {:live, :patch, %{kind: :push, to: "/"}} = response_socket.redirected
      assert %{"info" => "Tweet deleted"} = response_socket.assigns.flash
    end

    test "handle_event 'delete' pushes navigate to '/' and shows info flash", %{
      user: user
    } do
      tweet = tweet_fixture(%{}, user.id)

      socket = %LiveView.Socket{
        endpoint: TwitCloneWeb.Endpoint,
        assigns: %{
          __changed__: %{},
          flash: %{},
          current_user: user,
          user_id: user.id,
          source: :show,
          patch: "/"
        }
      }

      {:noreply, response_socket} =
        TwitCloneWeb.TweetLive.ActionsComponent.handle_event(
          "delete",
          %{"id" => tweet.id},
          socket
        )

      assert {:live, :redirect, %{kind: :push, to: "/"}} = response_socket.redirected
      assert %{"info" => "Tweet deleted"} = response_socket.assigns.flash
    end
  end

  describe "ActionsComponent when current_user is not tweet owner" do
    setup do
      tweet = tweet_fixture()
      user = AccountsFixtures.user_fixture()

      socket = %LiveView.Socket{
        endpoint: TwitCloneWeb.Endpoint,
        assigns: %{
          __changed__: %{},
          flash: %{},
          current_user: user,
          user_id: user.id,
          source: :index,
          patch: "/"
        }
      }

      {:noreply, response_socket} =
        TwitCloneWeb.TweetLive.ActionsComponent.handle_event(
          "delete",
          %{"id" => tweet.id},
          socket
        )

      %{socket: socket, response_socket: response_socket, tweet: tweet}
    end

    test "handle_event 'delete' does not delete tweet", %{
      tweet: tweet
    } do
      assert tweet == Repo.get!(Tweet, tweet.id)
    end

    test "handle_event 'delete' from :index pushes patch to assigned path and shows :error flash",
         %{
           response_socket: response_socket,
           socket: socket
         } do
      assert {:live, :patch, %{kind: :push, to: socket.assigns.patch}} ==
               response_socket.redirected

      assert %{"error" => "You can't delete someone else's tweets."} =
               response_socket.assigns.flash
    end

    test "handle_event 'delete' from :show pushes patch to assigned path and shows :error flash" do
      user = AccountsFixtures.user_fixture()
      tweet = tweet_fixture()

      socket = %LiveView.Socket{
        endpoint: TwitCloneWeb.Endpoint,
        assigns: %{
          __changed__: %{},
          flash: %{},
          current_user: user,
          user_id: user.id,
          source: :show,
          patch: "/"
        }
      }

      {:noreply, response_socket} =
        TwitCloneWeb.TweetLive.ActionsComponent.handle_event(
          "delete",
          %{"id" => tweet.id},
          socket
        )

      assert {:live, :patch, %{kind: :push, to: socket.assigns.patch}} ==
               response_socket.redirected

      assert %{"error" => "You can't delete someone else's tweets."} =
               response_socket.assigns.flash
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
