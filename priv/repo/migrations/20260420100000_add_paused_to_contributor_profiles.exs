defmodule WorthAsking.Repo.Migrations.AddPausedToContributorProfiles do
  use Ecto.Migration

  def change do
    alter table(:contributor_profiles) do
      add :paused, :boolean, default: false, null: false
      add :paused_reason, :string
      add :paused_at, :utc_datetime
    end
  end
end
