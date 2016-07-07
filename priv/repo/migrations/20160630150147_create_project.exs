defmodule ApiStorage.Repo.Migrations.CreateProject do
  use Ecto.Migration
  use Timex.Ecto.Timestamps

  def change do
    create table(:projects, primary_key: false) do
      add :id, :string, primary_key: true
      add :name, :string

      timestamps()
    end
  end
end
