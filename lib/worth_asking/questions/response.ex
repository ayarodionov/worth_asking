defmodule WorthAsking.Questions.Response do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "responses" do
    field :text, :string

    belongs_to :question, WorthAsking.Questions.Question
    belongs_to :contributor, WorthAsking.Accounts.User
    has_many :ratings, WorthAsking.Questions.Rating

    timestamps(type: :utc_datetime)
  end

  def changeset(response, attrs) do
    response
    |> cast(attrs, [:text])
    |> validate_required([:text])
    |> validate_length(:text, min: 20, max: 5000)
  end
end
