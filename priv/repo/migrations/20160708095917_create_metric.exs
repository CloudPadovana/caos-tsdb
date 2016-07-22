defmodule CaosApi.Repo.Migrations.CreateMetric do
  use Ecto.Migration

  def change do
    create table(:metrics, primary_key: false) do
      add :name, :string, primary_key: true
      add :type, :string

      timestamps()
    end

  end
end
