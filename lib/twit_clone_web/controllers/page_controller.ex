defmodule TwitCloneWeb.PageController do
  use TwitCloneWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
