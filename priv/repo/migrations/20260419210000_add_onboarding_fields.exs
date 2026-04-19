defmodule WorthAsking.Repo.Migrations.AddOnboardingFields do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :first_name, :string
      add :last_name, :string
    end

    alter table(:contributor_profiles) do
      add :age_range, :string
      add :location, :string
      add :onboarding_completed, :boolean, default: false
      add :sms_opt_in, :boolean, default: false
      add :availability_preference, :string, default: "anytime"
      add :agreed_to_terms, :boolean, default: false
    end
  end
end
