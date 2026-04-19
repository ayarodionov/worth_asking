defmodule WorthAsking.Questions.Question do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "questions" do
    field :text, :string
    field :category, Ecto.Enum,
      values: [:communication, :first_impressions, :style, :dating_dynamics]
    field :status, Ecto.Enum,
      values: [:pending, :answered, :paid],
      default: :pending
    field :image_paths, {:array, :string}, default: []

    belongs_to :user, WorthAsking.Accounts.User
    has_many :responses, WorthAsking.Questions.Response

    timestamps(type: :utc_datetime)
  end

  def changeset(question, attrs) do
    question
    |> cast(attrs, [:text, :category, :image_paths])
    |> validate_required([:text, :category])
    |> validate_length(:text, min: 10, max: 2000)
  end
end
