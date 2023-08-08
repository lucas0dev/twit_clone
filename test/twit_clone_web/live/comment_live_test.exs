defmodule TwitCloneWeb.CommentLiveTest do
  use TwitCloneWeb.ConnCase

  import Phoenix.LiveViewTest
  import TwitClone.TweetsFixtures
  import TwitClone.AccountsFixtures

  alias TwitClone.Repo
  alias Phoenix.LiveView
  alias TwitClone.Tweets.Comment

  defp create_tweet_with_comments(_) do
    tweet = tweet_fixture()
    tweet2 = tweet_fixture()
    user = user_fixture()
    comment = comment_fixture(tweet_id: tweet.id, user_id: user.id)
    comment2 = comment_fixture(tweet_id: tweet2.id)
    comment3 = comment_fixture(comment_id: comment2.id)
    %{comment: comment, tweet: tweet, comment3: comment3, user: user}
  end

  describe "CommentComponent" do
    setup [:create_tweet_with_comments]

    test "shows tweet comments and replies to comments", %{
      conn: conn,
      comment: comment,
      tweet: tweet,
      comment3: comment3
    } do
      {:ok, _lv, html} = live(conn, ~p"/tweets/#{tweet.id}")

      assert html =~ comment.body
      assert html =~ comment3.body
    end
  end

  describe "CommentComponent when user is owner of the comment" do
    setup [:create_tweet_with_comments]

    test "shows delete and edit button near the comment", %{
      conn: conn,
      user: user,
      tweet: tweet
    } do
      comment = comment_fixture(tweet_id: tweet.id, user_id: user.id)

      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/tweets/#{tweet.id}")

      assert lv |> element("#comment-#{comment.id} a", "Delete") |> has_element? == true
      assert lv |> element("#comment-#{comment.id} a", "Edit") |> has_element? == true
    end
  end

  describe "CommentComponent when user is not the owner of comment" do
    setup [:create_tweet_with_comments]

    test "delete and edit buttons are absent from the comment", %{
      conn: conn,
      user: user,
      tweet: tweet
    } do
      comment = comment_fixture(tweet_id: tweet.id)

      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/tweets/#{tweet.id}")

      assert lv |> element("#comment-#{comment.id}") |> has_element? == true

      assert lv |> element("#comment-#{comment.id} a", "Delete") |> has_element? == false
      assert lv |> element("#comment-#{comment.id} a", "Edit") |> has_element? == false
    end
  end

  describe "ActionsComponent when logged in user is comment owner" do
    setup [:create_tweet_with_comments]

    setup(assigns) do
      socket = %LiveView.Socket{
        endpoint: TwitCloneWeb.Endpoint,
        assigns: %{
          __changed__: %{},
          flash: %{},
          current_user: assigns.user,
          user_id: assigns.user.id,
          patch: "/"
        }
      }

      {:noreply, response_socket} =
        TwitCloneWeb.CommentLive.ActionsComponent.handle_event(
          "delete",
          %{"id" => assigns.comment.id},
          socket
        )

      %{socket: socket, response_socket: response_socket}
    end

    test "handle_event 'delete' deletes tweet", %{
      comment: comment
    } do
      assert_raise Ecto.NoResultsError, fn -> Repo.get!(Comment, comment.id) end
    end

    test "handle_event 'delete' redirects to '/tweets/tweet_id' and shows info flash", %{
      response_socket: response_socket,
      comment: comment
    } do
      tweet_id = comment.tweet_id

      assert {:live, :redirect, %{kind: :push, to: "/tweets/#{tweet_id}"}} ==
               response_socket.redirected

      assert %{"info" => "Comment deleted"} = response_socket.assigns.flash
    end
  end

  describe "ActionsComponent when logged in user is not the comment owner" do
    setup do
      tweet = tweet_fixture()
      comment = comment_fixture(tweet_id: tweet.id)
      user = user_fixture()

      socket = %LiveView.Socket{
        endpoint: TwitCloneWeb.Endpoint,
        assigns: %{
          __changed__: %{},
          flash: %{},
          current_user: user,
          user_id: user.id,
          patch: "/"
        }
      }

      {:noreply, response_socket} =
        TwitCloneWeb.CommentLive.ActionsComponent.handle_event(
          "delete",
          %{"id" => comment.id},
          socket
        )

      %{socket: socket, response_socket: response_socket, comment: comment}
    end

    test "handle_event 'delete' does not delete tweet", %{
      comment: comment
    } do
      assert comment == Repo.get!(Comment, comment.id)
    end

    test "handle_event 'delete' redirects to /tweets/tweet_id and shows :error flash",
         %{
           response_socket: response_socket,
           comment: comment
         } do
      tweet_id = comment.tweet_id

      assert {:live, :redirect, %{kind: :push, to: "/tweets/#{tweet_id}"}} ==
               response_socket.redirected

      assert %{"error" => "You can't delete someone else's comment."} =
               response_socket.assigns.flash
    end
  end

  describe "ActionsComponent when comment has any replies" do
    setup do
      tweet = tweet_fixture()
      user = user_fixture()
      comment = comment_fixture(tweet_id: tweet.id, user_id: user.id)
      comment_fixture(tweet_id: tweet.id, comment_id: comment.id)

      socket = %LiveView.Socket{
        endpoint: TwitCloneWeb.Endpoint,
        assigns: %{
          __changed__: %{},
          flash: %{},
          current_user: user,
          user_id: user.id,
          patch: "/"
        }
      }

      {:noreply, response_socket} =
        TwitCloneWeb.CommentLive.ActionsComponent.handle_event(
          "delete",
          %{"id" => comment.id},
          socket
        )

      %{socket: socket, response_socket: response_socket, comment: comment}
    end

    test "handle_event 'delete' does not delete tweet", %{
      comment: comment
    } do
      assert comment == Repo.get!(Comment, comment.id)
    end

    test "handle_event 'delete' redirects to /tweets/tweet_id and shows :error flash",
         %{
           response_socket: response_socket,
           comment: comment
         } do
      tweet_id = comment.tweet_id

      assert {:live, :redirect, %{kind: :push, to: "/tweets/#{tweet_id}"}} ==
               response_socket.redirected

      assert %{"error" => "You can't delete comment with replies."} =
               response_socket.assigns.flash
    end
  end
end
