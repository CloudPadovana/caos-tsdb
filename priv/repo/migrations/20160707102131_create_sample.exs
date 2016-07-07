defmodule ApiStorage.Repo.Migrations.CreateSample do
  use Ecto.Migration
  use Timex.Ecto.Timestamps

  def change do
    create table(:samples, primary_key: false) do
      add :project_id, references(:projects, type: :string), primary_key: true
      add :name, :string, primary_key: true
      add :value, :float

      timestamps()
    end

    create unique_index(:samples, [:project_id, :name])
  end
end
