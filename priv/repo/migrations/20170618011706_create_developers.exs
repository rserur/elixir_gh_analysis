defmodule ElixirGHAnalysis.Repo.Migrations.CreateDevelopers do
  use Ecto.Migration

  def change do
    create table(:developers) do
      add :name, :string
      add :language, :string
      add :repository_count, :integer, default: 0
    end
  end
end
