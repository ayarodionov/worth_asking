defmodule WorthAsking.Notifications.NotificationWave do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "notification_waves" do
    field :wave_number, :integer
    field :contributor_ids, {:array, :binary_id}, default: []
    field :notified_at, :utc_datetime
    field :status, :string, default: "pending"

    belongs_to :question, WorthAsking.Questions.Question

    timestamps(type: :utc_datetime)
  end

  def changeset(wave, attrs) do
    wave
    |> cast(attrs, [:wave_number, :contributor_ids, :notified_at, :status])
    |> validate_required([:wave_number])
  end
end
