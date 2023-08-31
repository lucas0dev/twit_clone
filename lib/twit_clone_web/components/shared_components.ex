defmodule TwitCloneWeb.SharedComponents do
  @moduledoc false

  use Phoenix.Component

  alias __MODULE__
  alias Phoenix.LiveView.JS

  import TwitCloneWeb.CoreComponents, only: [show_modal: 1]
  alias TwitCloneWeb.IconComponents

  attr :tweet_id, :string, required: true

  def actions_button(assigns) do
    ~H"""
    <button
      phx-click={
        JS.show(to: "#actions-#{@tweet_id}") |> JS.remove_attribute("phx-click", to: ".tweet")
      }
      class="actions-button h-6 self-start ml-auto text-white hover:outline-1 font-medium rounded-lg text-sm  text-center inline-flex justify-self-end"
      type="button"
    >
      <IconComponents.three_dot />
    </button>
    """
  end

  attr :comments_count, :any, required: true
  attr :tweet_id, :integer, required: true
  attr :user, :any, required: true

  def tweet_social_actions(assigns) do
    ~H"""
    <div class="mt-4 w-full flex gap-8 justify-evenly">
      <button
        class="new-comment flex gap-2 items-center fill-black hover:fill-orange-600 hover:text-orange-600"
        phx-click={
          if @user do
            show_modal("comment-modal") |> JS.push("new_comment", value: %{tweet_id: @tweet_id})
          else
            "redirect"
          end
        }
      >
        <div class="w-4">
          <IconComponents.comment />
        </div>
        <div>
          <%= @comments_count %>
        </div>
      </button>
      <SharedComponents.actions_bar />
    </div>
    """
  end

  attr :comments_count, :any, required: true
  attr :comment_id, :string, required: true
  attr :user, :map, required: true

  def comment_social_actions(assigns) do
    ~H"""
    <div class="mt-4 w-full flex gap-8 justify-evenly">
      <button
        class="add-comment flex gap-2 items-center fill-black hover:fill-orange-600 hover:text-orange-600"
        phx-click={
          if @user do
            JS.push("new_comment", value: %{comment_id: @comment_id})
          else
            "redirect"
          end
        }
      >
        <div class="w-4">
          <IconComponents.comment />
        </div>
        <%= if @comments_count != nil do %>
          <div>
            <%= @comments_count %>
          </div>
        <% else %>
          <div>
            Reply
          </div>
        <% end %>
      </button>
      <SharedComponents.actions_bar />
    </div>
    """
  end

  def actions_bar(assigns) do
    ~H"""
    <button class="flex gap-2 items-center fill-black hover:fill-orange-600 hover:text-orange-600">
      <div class="w-5">
        <IconComponents.retweet />
      </div>
      <div>
        0
      </div>
    </button>
    <button class="flex gap-2 items-center stroke-black hover:stroke-orange-600 hover:text-orange-600">
      <div class="w-5">
        <IconComponents.like />
      </div>
      <div>
        0
      </div>
    </button>
    <div class="flex gap-2 items-cente fill-black ">
      <div class="w-5 my-auto">
        <IconComponents.views />
      </div>
      <div>
        0
      </div>
    </div>
    """
  end
end
