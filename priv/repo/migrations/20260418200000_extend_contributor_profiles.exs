defmodule WorthAsking.Repo.Migrations.ExtendContributorProfiles do
  use Ecto.Migration

  def change do
    alter table(:contributor_profiles) do
      add :display_name, :string, null: false, default: "Anonymous"
      add :specialties, {:array, :string}, default: [], null: false
      add :application_status, :string, default: "pending", null: false
      add :sample_responses, :map, default: %{}
      add :earnings_cents, :integer, default: 0, null: false
      add :response_count, :integer, default: 0, null: false
      add :average_rating, :float
      add :avatar_path, :string
    end

    create index(:contributor_profiles, [:application_status])
  end
end
