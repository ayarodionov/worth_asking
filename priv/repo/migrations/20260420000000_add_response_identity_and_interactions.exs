defmodule WorthAsking.Repo.Migrations.AddResponseIdentityAndInteractions do
  use Ecto.Migration

  def change do
    alter table(:responses) do
      add :alias_name, :string
      add :age_range, :string
    end

    create table(:response_interactions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :type, :string, null: false
      add :response_id, references(:responses, type: :binary_id, on_delete: :delete_all), null: false
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:response_interactions, [:response_id, :user_id, :type])
    create index(:response_interactions, [:user_id])
  end
end
