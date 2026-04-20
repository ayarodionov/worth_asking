defmodule WorthAsking.Repo.Migrations.CreateAdmins do
  use Ecto.Migration

  def change do
    create table(:admins, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :email, :string, null: false
      add :hashed_password, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:admins, [:email])

    create table(:admin_tokens, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :token, :binary, null: false
      add :context, :string, null: false
      add :admin_id, references(:admins, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:admin_tokens, [:admin_id])
  end
end
