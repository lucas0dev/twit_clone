defmodule TwitClone.Repo do
  use Ecto.Repo,
    otp_app: :twit_clone,
    adapter: Ecto.Adapters.Postgres
end
