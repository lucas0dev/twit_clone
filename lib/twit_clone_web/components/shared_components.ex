defmodule TwitCloneWeb.SharedComponents do
  @moduledoc false

  use Phoenix.Component

  alias __MODULE__
  alias Phoenix.LiveView.JS

  import TwitCloneWeb.CoreComponents, only: [show_modal: 1]

  attr :tweet_id, :string, required: true

  def actions_button(assigns) do
    ~H"""
    <button
      phx-click={
        JS.show(to: "#actions-#{@tweet_id}") |> JS.remove_attribute("phx-click", to: ".tweet")
      }
      class="h-6 self-start ml-auto text-white hover:outline-1 font-medium rounded-lg text-sm  text-center inline-flex justify-self-end"
      type="button"
    >
      <svg
        viewBox="0 0 24 24"
        height="100%"
        aria-hidden="true"
        class="r-4qtqp9 r-yyyyoo r-1xvli5t r-dnmrzs r-bnwqim r-1plcrui r-lrvibr r-1hdv0qi"
      >
        <g>
          <path d="M3 12c0-1.1.9-2 2-2s2 .9 2 2-.9 2-2 2-2-.9-2-2zm9 2c1.1 0 2-.9 2-2s-.9-2-2-2-2 .9-2 2 .9 2 2 2zm7 0c1.1 0 2-.9 2-2s-.9-2-2-2-2 .9-2 2 .9 2 2 2z">
          </path>
        </g>
      </svg>
    </button>
    """
  end

  attr :tweet_id, :string, required: true

  def tweet_actions(assigns) do
    ~H"""
    <div
      id={"actions-#{@tweet_id}" }
      class=" absolute right-0 top-[8px] z-10 hidden border-2 bg-white divide-y divide-gray-100  shadow w-44 "
      phx-click-away={
        JS.hide(transition: "fade-out", to: "#actions-#{@tweet_id}")
        |> JS.set_attribute({"phx-click", "show_tweet"}, to: ".tweet")
      }
      phx-window-keydown={
        JS.hide(transition: "fade-out", to: "#actions-#{@tweet_id}")
        |> JS.set_attribute({"phx-click", "show_tweet"}, to: ".tweet")
      }
      phx-key="escape"
    >
      <ul class="text-sm text-gray-700 dark:text-gray-200" aria-labelledby="dropdownDefaultButton">
        <li>
          <a
            href="#"
            class="text-black block px-4 py-2 hover:bg-gray-100 dark:hover:bg-gray-600 dark:hover:text-white"
          >
            Edit
          </a>
        </li>
        <li>
          <a
            href="#"
            class="text-black block px-4 py-2 hover:bg-gray-100 dark:hover:bg-gray-600 dark:hover:text-white"
          >
            Delete
          </a>
        </li>
      </ul>
    </div>
    """
  end

  attr :comments_count, :any, required: true
  attr :tweet_id, :integer, required: true

  def tweet_actions_bar(assigns) do
    ~H"""
    <div class="mt-4 w-full flex gap-8 justify-evenly">
      <button
        class="flex gap-2 items-center fill-black hover:fill-orange-600 hover:text-orange-600"
        phx-click={
          show_modal("comment-modal") |> JS.push("new_comment", value: %{tweet_id: @tweet_id})
        }
      >
        <div class="w-4">
          <svg
            version="1.1"
            xmlns="http://www.w3.org/2000/svg"
            xmlns:xlink="http://www.w3.org/1999/xlink"
            viewBox="0 0 458 458"
            xml:space="preserve"
          >
            <g stroke-width="0"></g>
            <g stroke-linecap="round" stroke-linejoin="round"></g>
            <g>
              <g>
                <g>
                  <path d="M428,41.534H30c-16.569,0-30,13.431-30,30v252c0,16.568,13.432,30,30,30h132.1l43.942,52.243 c5.7,6.777,14.103,10.69,22.959,10.69c8.856,0,17.258-3.912,22.959-10.69l43.942-52.243H428c16.568,0,30-13.432,30-30v-252 C458,54.965,444.568,41.534,428,41.534z M323.916,281.534H82.854c-8.284,0-15-6.716-15-15s6.716-15,15-15h241.062 c8.284,0,15,6.716,15,15S332.2,281.534,323.916,281.534z M67.854,198.755c0-8.284,6.716-15,15-15h185.103c8.284,0,15,6.716,15,15 s-6.716,15-15,15H82.854C74.57,213.755,67.854,207.039,67.854,198.755z M375.146,145.974H82.854c-8.284,0-15-6.716-15-15 s6.716-15,15-15h292.291c8.284,0,15,6.716,15,15C390.146,139.258,383.43,145.974,375.146,145.974z">
                  </path>
                </g>
              </g>
            </g>
          </svg>
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

  def comment_actions_bar(assigns) do
    ~H"""
    <div class="mt-4 w-full flex gap-8 justify-evenly">
      <button
        class="flex gap-2 items-center fill-black hover:fill-orange-600 hover:text-orange-600"
        phx-click={JS.push("assign_reply", value: %{comment_id: @comment_id})}
      >
        <div class="w-4">
          <svg
            version="1.1"
            xmlns="http://www.w3.org/2000/svg"
            xmlns:xlink="http://www.w3.org/1999/xlink"
            viewBox="0 0 458 458"
            xml:space="preserve"
          >
            <g stroke-width="0"></g>
            <g stroke-linecap="round" stroke-linejoin="round"></g>
            <g>
              <g>
                <g>
                  <path d="M428,41.534H30c-16.569,0-30,13.431-30,30v252c0,16.568,13.432,30,30,30h132.1l43.942,52.243 c5.7,6.777,14.103,10.69,22.959,10.69c8.856,0,17.258-3.912,22.959-10.69l43.942-52.243H428c16.568,0,30-13.432,30-30v-252 C458,54.965,444.568,41.534,428,41.534z M323.916,281.534H82.854c-8.284,0-15-6.716-15-15s6.716-15,15-15h241.062 c8.284,0,15,6.716,15,15S332.2,281.534,323.916,281.534z M67.854,198.755c0-8.284,6.716-15,15-15h185.103c8.284,0,15,6.716,15,15 s-6.716,15-15,15H82.854C74.57,213.755,67.854,207.039,67.854,198.755z M375.146,145.974H82.854c-8.284,0-15-6.716-15-15 s6.716-15,15-15h292.291c8.284,0,15,6.716,15,15C390.146,139.258,383.43,145.974,375.146,145.974z">
                  </path>
                </g>
              </g>
            </g>
          </svg>
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
        <svg
          version="1.1"
          xmlns="http://www.w3.org/2000/svg"
          xmlns:xlink="http://www.w3.org/1999/xlink"
          viewBox="0 0 512 512"
          xml:space="preserve"
        >
          <g stroke-width="0"></g>
          <g stroke-linecap="round" stroke-linejoin="round"></g>
          <g>
            <g>
              <path
                class="st0"
                d="M509.86,267.434c-2.785-4.717-7.858-7.613-13.338-7.613h-43.677v-108.21 c0.014-19.402-7.962-37.293-20.698-49.971c-12.678-12.738-30.57-20.721-49.973-20.699l-194.482-0.007 c-6.088,0-11.731,3.222-14.818,8.472c-3.089,5.243-3.178,11.738-0.222,17.062l17.55,31.65c3.792,6.828,10.99,11.072,18.795,11.072 h173.178c0.786,0.014,1.17,0.214,1.71,0.703c0.49,0.548,0.696,0.933,0.711,1.718v108.21h-43.678c-5.48,0-10.553,2.896-13.338,7.613 c-2.777,4.74-2.858,10.575-0.199,15.374l77.802,140.29c2.726,4.918,7.91,7.969,13.538,7.969s10.812-3.051,13.537-7.969 l77.802-140.29C512.719,278.009,512.637,272.174,509.86,267.434z"
              >
              </path>

              <path
                class="st0"
                d="M321.791,373.873c-3.792-6.835-10.983-11.071-18.796-11.071h-173.17c-0.785-0.014-1.17-0.214-1.711-0.703 c-0.488-0.541-0.696-0.926-0.71-1.71v-108.21h43.678c5.473,0,10.553-2.896,13.337-7.613c2.778-4.74,2.859-10.575,0.201-15.374 l-77.802-140.29c-2.733-4.918-7.91-7.969-13.537-7.969c-5.629,0-10.805,3.051-13.538,7.969L1.94,229.192 c-2.658,4.798-2.577,10.634,0.2,15.374c2.785,4.717,7.865,7.613,13.338,7.613h43.678v108.21 c-0.015,19.402,7.961,37.294,20.698,49.972c12.678,12.737,30.57,20.714,49.972,20.69l194.476,0.008 c6.086,0,11.73-3.222,14.818-8.472c3.087-5.251,3.177-11.738,0.222-17.07L321.791,373.873z"
              >
              </path>
            </g>
          </g>
        </svg>
      </div>
      <div>
        0
      </div>
    </button>
    <button class="flex gap-2 items-center stroke-black hover:stroke-orange-600 hover:text-orange-600">
      <div class="w-5">
        <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
          <g stroke-width="0"></g>
          <g stroke-linecap="round" stroke-linejoin="round"></g>
          <g>
            <path
              d="M8 10V20M8 10L4 9.99998V20L8 20M8 10L13.1956 3.93847C13.6886 3.3633 14.4642 3.11604 15.1992 3.29977L15.2467 3.31166C16.5885 3.64711 17.1929 5.21057 16.4258 6.36135L14 9.99998H18.5604C19.8225 9.99998 20.7691 11.1546 20.5216 12.3922L19.3216 18.3922C19.1346 19.3271 18.3138 20 17.3604 20L8 20"
              stroke-width="1.5"
              stroke-linecap="round"
              stroke-linejoin="round"
            >
            </path>
          </g>
        </svg>
      </div>
      <div>
        0
      </div>
    </button>
    <div class="flex gap-2 items-cente fill-black ">
      <div class="w-5 my-auto">
        <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
          <g stroke-width="0"></g>
          <g stroke-linecap="round" stroke-linejoin="round"></g>
          <g>
            <path
              fill-rule="evenodd"
              clip-rule="evenodd"
              d="M12 9C10.3431 9 9 10.3431 9 12C9 13.6569 10.3431 15 12 15C13.6569 15 15 13.6569 15 12C15 10.3431 13.6569 9 12 9ZM11 12C11 11.4477 11.4477 11 12 11C12.5523 11 13 11.4477 13 12C13 12.5523 12.5523 13 12 13C11.4477 13 11 12.5523 11 12Z"
            >
            </path>

            <path
              fill-rule="evenodd"
              clip-rule="evenodd"
              d="M21.83 11.2807C19.542 7.15186 15.8122 5 12 5C8.18777 5 4.45796 7.15186 2.17003 11.2807C1.94637 11.6844 1.94361 12.1821 2.16029 12.5876C4.41183 16.8013 8.1628 19 12 19C15.8372 19 19.5882 16.8013 21.8397 12.5876C22.0564 12.1821 22.0536 11.6844 21.83 11.2807ZM12 17C9.06097 17 6.04052 15.3724 4.09173 11.9487C6.06862 8.59614 9.07319 7 12 7C14.9268 7 17.9314 8.59614 19.9083 11.9487C17.9595 15.3724 14.939 17 12 17Z"
            >
            </path>
          </g>
        </svg>
      </div>
      <div>
        0
      </div>
    </div>
    """
  end
end
