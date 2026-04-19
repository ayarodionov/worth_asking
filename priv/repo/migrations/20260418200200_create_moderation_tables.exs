defmodule WorthAsking.Repo.Migrations.CreateModerationTables do
  use Ecto.Migration

  def change do
    create table(:reports, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :reporter_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :reported_user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :reported_content_type, :string, null: false
      add :reported_content_id, :binary_id
      add :reason, :string, null: false
      add :description, :text
      add :status, :string, null: false, default: "pending"
      add :admin_notes, :text

      timestamps(type: :utc_datetime)
    end

    create index(:reports, [:status])
    create index(:reports, [:reporter_id])
    create index(:reports, [:reported_user_id])

    create table(:blocks, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :blocker_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :blocked_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:blocks, [:blocker_id, :blocked_id])
    create index(:blocks, [:blocked_id])
  end
end
