defmodule WorthAsking.Repo.Migrations.AddAvailabilityFields do
  use Ecto.Migration

  def change do
    alter table(:contributor_profiles) do
      add :available_now, :boolean, default: false
      add :available_until, :utc_datetime
      add :accept_basic, :boolean, default: true
      add :accept_interactive, :boolean, default: true
      add :accept_fast, :boolean, default: false
      add :active_session_count, :integer, default: 0
      add :max_active_sessions, :integer, default: 2
    end

    alter table(:questions) do
      add :session_type, :string, default: "basic"
      add :assigned_contributor_id, references(:users, type: :binary_id, on_delete: :nothing)
      add :assigned_at, :utc_datetime
    end

    create table(:notification_waves, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :question_id, references(:questions, type: :binary_id, on_delete: :delete_all), null: false
      add :wave_number, :integer, null: false
      add :contributor_ids, {:array, :binary_id}, default: []
      add :notified_at, :utc_datetime
      add :status, :string, default: "pending"

      timestamps(type: :utc_datetime)
    end

    create index(:notification_waves, [:question_id])
    create unique_index(:notification_waves, [:question_id, :wave_number])
  end
end
