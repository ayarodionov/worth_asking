defmodule WorthAsking.Moderation.Report do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "reports" do
    field :reported_content_type, :string
    field :reported_content_id, :binary_id
    field :reason, Ecto.Enum, values: [:harassment, :inappropriate, :spam, :other]
    field :description, :string
    field :status, Ecto.Enum,
      values: [:pending, :reviewed, :resolved, :dismissed],
      default: :pending
    field :admin_notes, :string

    belongs_to :reporter, WorthAsking.Accounts.User
    belongs_to :reported_user, WorthAsking.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(report, attrs) do
    report
    |> cast(attrs, [
      :reported_user_id,
      :reported_content_type,
      :reported_content_id,
      :reason,
      :description,
      :status,
      :admin_notes
    ])
    |> validate_required([:reason, :reported_content_type])
    |> foreign_key_constraint(:reporter_id)
    |> foreign_key_constraint(:reported_user_id)
  end
end
