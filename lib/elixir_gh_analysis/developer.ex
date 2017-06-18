defmodule ElixirGHAnalysis.Developer do
  use Ecto.Schema

  schema "developers" do
    field :name, :string
    field :language, :string
    field :repository_count, :integer, default: 0
  end

  def changeset(developer, params \\ %{}) do
    developer
    |> Ecto.Changeset.cast(params, ~w(name language repository_count))
    |> Ecto.Changeset.validate_required([:name, :language, :repository_count])
  end
end
