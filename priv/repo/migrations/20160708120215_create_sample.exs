defmodule ApiStorage.Repo.Migrations.CreateSample do
  use Ecto.Migration

  def change do
    create table(:samples, primary_key: false) do
      add :series_id, references(:series, column: :id, type: :serial), primary_key: true
      add :timestamp, :datetime, primary_key: true
      add :value, :float

      timestamps()
    end

    create unique_index(:samples, [:series_id, :timestamp])
  end
end
