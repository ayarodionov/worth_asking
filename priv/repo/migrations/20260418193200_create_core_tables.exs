defmodule WorthAsking.Repo.Migrations.CreateCoreTables do
  use Ecto.Migration

  def change do
    create table(:contributor_profiles, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :bio, :text
      add :categories, {:array, :string}, null: false, default: []
      add :verified, :boolean, default: false, null: false
      add :stripe_connect_id, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:contributor_profiles, [:user_id])
    create index(:contributor_profiles, [:verified])

    create table(:questions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :text, :text, null: false
      add :category, :string, null: false
      add :status, :string, null: false, default: "pending"

      timestamps(type: :utc_datetime)
    end

    create index(:questions, [:user_id])
    create index(:questions, [:category])
    create index(:questions, [:status])

    create table(:responses, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :question_id, references(:questions, type: :binary_id, on_delete: :delete_all), null: false
      add :contributor_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :text, :text, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:responses, [:question_id])
    create index(:responses, [:contributor_id])

    create table(:payments, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :question_id, references(:questions, type: :binary_id, on_delete: :delete_all), null: false
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :stripe_session_id, :string
      add :amount_cents, :integer, null: false
      add :status, :string, null: false, default: "pending"

      timestamps(type: :utc_datetime)
    end

    create index(:payments, [:question_id])
    create index(:payments, [:user_id])
    create unique_index(:payments, [:stripe_session_id], where: "stripe_session_id IS NOT NULL")

    create table(:ratings, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :response_id, references(:responses, type: :binary_id, on_delete: :delete_all), null: false
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :score, :integer, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:ratings, [:response_id])
    create unique_index(:ratings, [:response_id, :user_id])
  end
end
