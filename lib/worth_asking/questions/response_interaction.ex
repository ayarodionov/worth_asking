defmodule WorthAsking.Questions.ResponseInteraction do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "response_interactions" do
    field :type, :string

    belongs_to :response, WorthAsking.Questions.Response
    belongs_to :user, WorthAsking.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(interaction, attrs) do
    interaction
    |> cast(attrs, [:type])
    |> validate_required([:type])
    |> validate_inclusion(:type, ["like", "save"])
  end
end
