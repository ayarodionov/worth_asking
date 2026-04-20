defmodule WorthAsking.Questions.Response do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "responses" do
    field :text, :string
    field :alias_name, :string
    field :age_range, :string

    belongs_to :question, WorthAsking.Questions.Question
    belongs_to :contributor, WorthAsking.Accounts.User
    has_many :ratings, WorthAsking.Questions.Rating
    has_many :interactions, WorthAsking.Questions.ResponseInteraction

    timestamps(type: :utc_datetime)
  end

  @age_ranges ["20-25", "25-30", "30-35", "35-40", "40+"]

  def changeset(response, attrs) do
    response
    |> cast(attrs, [:text, :alias_name, :age_range])
    |> validate_required([:text, :alias_name, :age_range])
    |> validate_length(:text, min: 150, max: 5000)
    |> validate_length(:alias_name, min: 2, max: 30)
    |> validate_inclusion(:age_range, @age_ranges)
  end

  def age_ranges, do: @age_ranges
end
