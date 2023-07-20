defmodule TwitCloneWeb.CommentLive.CommentComponent do
  use TwitCloneWeb, :live_component

  alias TwitClone.Tweets
  alias TwitCloneWeb.SharedComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div id={"comment_#{@comment.id}"} class="border-2 shadow-md rounded-md">
      <div class="flex flex-col mt-4 px-2 pb-4">
        <div>
          <div class="flex flex-row">
            <img class="h-12 w-12 rounded-full" src={@comment.user.avatar} />
            <div class="ml-2 flex flex-col">
              <div>
                <span class="font-serif italic"><%= @comment.user.name %></span>
                <span class="italic font-light">@<%= @comment.user.account_name %></span>
              </div>
              <div class="break-all">
                <%= @comment.body %>
              </div>
              <%= if @comment.image != nil do %>
                <div class="mt-5 border mx-auto rounded-md p-2 shadow-md">
                  <img class="max-h-80 mx-auto" src={@comment.image} />
                </div>
              <% end %>
            </div>
          </div>
          <div class="flex flex-col">
            <SharedComponents.comment_actions_bar
              comments_count={length(@comment.replies)}
              comment_id={@comment.id}
            />
          </div>
        </div>
        <%= for reply <- @comment.replies do %>
          <div class="pl-8">
            <div class="flex flex-row py-2 mt-4 border-t-2 px-2">
              <img class="h-12 w-12 rounded-full" src={reply.user.avatar} />
              <div class="ml-2 flex flex-col">
                <div>
                  <span class="font-serif italic"><%= reply.user.name %></span>
                  <span class="italic font-light">@<%= reply.user.account_name %></span>
                </div>
                <div class="break-all">
                  <%= reply.body %>
                </div>
                <%= if reply.image != nil do %>
                  <div class="mt-5 border mx-auto rounded-md p-2 shadow-md">
                    <img class="max-h-80 mx-auto" src={reply.image} />
                  </div>
                <% end %>
              </div>
            </div>
            <SharedComponents.comment_actions_bar comments_count={nil} comment_id={@comment.id} />
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  @impl true
  def update(%{comment: comment} = assigns, socket) do
    changeset = Tweets.change_comment(comment)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)
     |> allow_upload(:image, accept: ~w(.jpg .jpeg .png), max_entries: 1, auto_upload: true)}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
