defmodule WorthAsking.Admin.AdminToken do
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "admin_tokens" do
    field :token, :binary
    field :context, :string
    belongs_to :admin, WorthAsking.Admin.Admin

    timestamps(type: :utc_datetime, updated_at: false)
  end
end
