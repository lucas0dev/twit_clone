defmodule TwitCloneWeb.CommentLiveTest do
  use TwitCloneWeb.ConnCase

  import Phoenix.LiveViewTest
  import TwitClone.TweetsFixtures
  import TwitClone.AccountsFixtures

  alias TwitClone.Repo
  alias TwitClone.Tweets
  alias Phoenix.LiveView
  alias TwitClone.Tweets.Comment
  alias TwitCloneWeb.CommentLive.CommentComponent

  defp create_tweet_with_comments(_) do
    tweet = tweet_fixture()
    tweet2 = tweet_fixture()
    user = user_fixture()
    comment = comment_fixture(parent_tweet_id: tweet.id, user_id: user.id)
    comment2 = comment_fixture(parent_tweet_id: tweet2.id)
    comment3 = comment_fixture(parent_tweet_id: comment2.id)
    %{comment: comment, tweet: tweet, comment3: comment3, user: user}
  end

  describe "CommentComponent" do
    setup do
      tweet = tweet_fixture()
      comment = comment_fixture(parent_tweet_id: tweet.id)
      comment_fixture(parent_tweet_id: comment.id)
      user = user_fixture()
      tweet = Tweets.get_tweet_with_assoc(tweet.id)
      comment_with_replies = List.first(tweet.comments)
      comment_reply = List.first(comment_with_replies.replies)

      rendered_component =
        render_component(CommentComponent,
          id: 123,
          comment: comment_with_replies,
          user: user,
          avatar: user.avatar
        )

      %{
        rendered_component: rendered_component,
        reply: comment_reply,
        comment: comment_with_replies
      }
    end

    test "shows tweet comments and replies to comments", %{
      rendered_component: rendered_component,
      reply: reply,
      comment: comment
    } do
      assert rendered_component =~ reply.body
      assert rendered_component =~ comment.body
    end
  end

  describe "CommentComponent when user is owner of the comment" do
    setup [:create_tweet_with_comments]

    test "shows delete and edit button near the comment", %{
      user: user,
      tweet: tweet
    } do
      tweet = Tweets.get_tweet_with_assoc(tweet.id)
      comment = List.first(tweet.comments)

      result =
        render_component(CommentComponent,
          id: 123,
          comment: comment,
          user: user,
          avatar: user.avatar,
          path: "/tweets/#{tweet.id}"
        )

      assert result =~ "Delete"
      assert result =~ "Edit"
    end
  end

  describe "CommentComponent when user is owner of the reply to comment" do
    setup [:create_tweet_with_comments]

    test "shows delete and edit button near the reply", %{
      user: user,
      tweet: tweet
    } do
      tweet_comment = comment_fixture(parent_tweet_id: tweet.id)
      comment_fixture(user_id: user.id, parent_tweet_id: tweet_comment.id)
      tweet = Tweets.get_tweet_with_assoc(tweet.id)
      comment = Enum.find(tweet.comments, nil, fn comment -> comment.id == tweet_comment.id end)

      result =
        render_component(CommentComponent,
          id: 123,
          comment: comment,
          user: user,
          avatar: user.avatar,
          path: "/tweets/#{tweet.id}"
        )

      assert result =~ "Delete"
      assert result =~ "Edit"
    end
  end

  describe "CommentComponent when user is not the owner of comment" do
    test "delete and edit buttons are absent from the comment", %{} do
      user = user_fixture()
      tweet = tweet_fixture()
      tweet_comment = comment_fixture(parent_tweet_id: tweet.id)
      comment_fixture(parent_tweet_id: tweet_comment.id)
      tweet = Tweets.get_tweet_with_assoc(tweet.id)
      comment = Enum.find(tweet.comments, nil, fn comment -> comment.id == tweet_comment.id end)

      result =
        render_component(CommentComponent,
          id: 123,
          comment: comment,
          user: user,
          avatar: user.avatar,
          path: "/tweets/#{tweet.id}"
        )

      refute result =~ "Delete"
      refute result =~ "Edit"
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
          patch: "/",
          path: "/tweets/#{assigns.tweet.id}"
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
      tweet_id = comment.parent_tweet_id

      assert {:live, :redirect, %{kind: :push, to: "/tweets/#{tweet_id}"}} ==
               response_socket.redirected

      assert %{"info" => "Comment deleted"} = response_socket.assigns.flash
    end
  end

  describe "ActionsComponent when logged in user is not the comment owner" do
    setup do
      tweet = tweet_fixture()
      comment = comment_fixture(parent_tweet_id: tweet.id)
      user = user_fixture()

      socket = %LiveView.Socket{
        endpoint: TwitCloneWeb.Endpoint,
        assigns: %{
          __changed__: %{},
          flash: %{},
          current_user: user,
          user_id: user.id,
          patch: "/",
          path: "/tweets/#{tweet.id}"
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
      tweet_id = comment.parent_tweet_id

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
      comment = comment_fixture(parent_tweet_id: tweet.id, user_id: user.id)
      comment_fixture(parent_tweet_id: comment.id)

      socket = %LiveView.Socket{
        endpoint: TwitCloneWeb.Endpoint,
        assigns: %{
          __changed__: %{},
          flash: %{},
          current_user: user,
          user_id: user.id,
          patch: "/",
          path: "/tweets/#{tweet.id}"
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

    test "handle_event 'delete' does not delete comment", %{
      comment: comment
    } do
      assert comment == Repo.get!(Comment, comment.id)
    end

    test "handle_event 'delete' redirects to /tweets/tweet_id and shows :error flash",
         %{
           response_socket: response_socket,
           comment: comment
         } do
      tweet_id = comment.parent_tweet_id

      assert {:live, :redirect, %{kind: :push, to: "/tweets/#{tweet_id}"}} ==
               response_socket.redirected

      assert %{"error" => "You can't delete comment with replies."} =
               response_socket.assigns.flash
    end
  end

  describe "FormComponent" do
    setup do
      tweet = tweet_fixture()
      user = user_fixture()

      %{tweet: tweet, user: user}
    end

    test "creates new comment", %{conn: conn, tweet: tweet, user: user} do
      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/tweets/#{tweet.id}")

      assert view
             |> element("#add-tweet-comment")
             |> render_click()

      assert view
             |> form("#new-comment-form", comment: %{"body" => "asdqwe"})
             |> render_submit()

      [comment] = Tweets.get_comments()
      assert comment.body == "asdqwe"
      assert comment.parent_tweet_id == tweet.id
    end

    test "creates new reply to comment", %{conn: conn, tweet: tweet, user: user} do
      comment = comment_fixture(parent_tweet_id: tweet.id)
      body = "comment body"

      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/tweets/#{tweet.id}")

      assert view
             |> element("button.add-comment")
             |> render_click()

      assert view
             |> form("#new-comment-form", comment: %{"body" => body})
             |> render_submit()

      comments = Tweets.get_comments()
      new_comment = List.last(comments)

      assert new_comment.body == body
      assert new_comment.parent_tweet_id == comment.id
    end
  end
end
