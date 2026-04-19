defmodule WorthAsking.Questions.Rating do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "ratings" do
    field :score, :integer

    belongs_to :response, WorthAsking.Questions.Response
    belongs_to :user, WorthAsking.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(rating, attrs) do
    rating
    |> cast(attrs, [:score])
    |> validate_required([:score])
    |> validate_inclusion(:score, 1..5)
  end
end
