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
    field :session_type, :string, default: "basic"
    field :image_paths, {:array, :string}, default: []
    field :assigned_at, :utc_datetime

    belongs_to :user, WorthAsking.Accounts.User
    belongs_to :assigned_contributor, WorthAsking.Accounts.User
    has_many :responses, WorthAsking.Questions.Response

    timestamps(type: :utc_datetime)
  end

  def changeset(question, attrs) do
    question
    |> cast(attrs, [:text, :category, :image_paths, :session_type])
    |> validate_required([:text, :category])
    |> validate_length(:text, min: 10, max: 2000)
  end
end
