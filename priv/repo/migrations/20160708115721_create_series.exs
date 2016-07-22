defmodule CaosApi.Repo.Migrations.CreateSeries do
  use Ecto.Migration

  def change do
    create table(:series, primary_key: false) do
      add :id, :serial, primary_key: true

      add :project_id, references(:projects, column: :id, type: :string), primary_key: true
      add :metric_name, references(:metrics, column: :name, type: :string), primary_key: true
      add :period, :integer, primary_key: true
      add :ttl, :integer
      add :last_timestamp, :datetime
      timestamps()
    end

    create unique_index(:series, [:project_id, :metric_name, :period])
  end
end
