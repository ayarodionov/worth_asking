defmodule WorthAsking.Repo.Migrations.AddQuestionImages do
  use Ecto.Migration

  def change do
    alter table(:questions) do
      add :image_paths, {:array, :string}, default: [], null: false
    end
  end
end
