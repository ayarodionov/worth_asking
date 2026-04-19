defmodule WorthAsking.Questions.Payment do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "payments" do
    field :stripe_session_id, :string
    field :stripe_payment_intent_id, :string
    field :amount_cents, :integer
    field :contributor_payout_cents, :integer
    field :platform_fee_cents, :integer
    field :transfer_id, :string
    field :status, Ecto.Enum,
      values: [:pending, :completed, :failed],
      default: :pending

    belongs_to :question, WorthAsking.Questions.Question
    belongs_to :user, WorthAsking.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(payment, attrs) do
    payment
    |> cast(attrs, [:stripe_session_id, :stripe_payment_intent_id, :amount_cents,
                    :contributor_payout_cents, :platform_fee_cents, :transfer_id, :status])
    |> validate_required([:amount_cents])
  end
end
