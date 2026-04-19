defmodule WorthAsking.Repo do
  use Ecto.Repo,
    otp_app: :worth_asking,
    adapter: Ecto.Adapters.Postgres
end
