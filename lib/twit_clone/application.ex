defmodule TwitClone.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      TwitCloneWeb.Telemetry,
      # Start the Ecto repository
      TwitClone.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: TwitClone.PubSub},
      # Start Finch
      {Finch, name: TwitClone.Finch},
      # Start the Endpoint (http/https)
      TwitCloneWeb.Endpoint
      # Start a worker by calling: TwitClone.Worker.start_link(arg)
      # {TwitClone.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TwitClone.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TwitCloneWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
