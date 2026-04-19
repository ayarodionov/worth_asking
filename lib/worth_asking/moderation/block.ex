defmodule WorthAsking.Moderation.Block do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "blocks" do
    belongs_to :blocker, WorthAsking.Accounts.User
    belongs_to :blocked, WorthAsking.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(block, attrs) do
    block
    |> cast(attrs, [:blocker_id, :blocked_id])
    |> validate_required([:blocker_id, :blocked_id])
    |> foreign_key_constraint(:blocker_id)
    |> foreign_key_constraint(:blocked_id)
    |> unique_constraint([:blocker_id, :blocked_id])
  end
end
