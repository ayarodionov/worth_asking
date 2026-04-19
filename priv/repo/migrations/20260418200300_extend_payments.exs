defmodule WorthAsking.Repo.Migrations.ExtendPayments do
  use Ecto.Migration

  def change do
    alter table(:payments) do
      add :stripe_payment_intent_id, :string
      add :contributor_payout_cents, :integer
      add :platform_fee_cents, :integer
      add :transfer_id, :string
    end
  end
end
