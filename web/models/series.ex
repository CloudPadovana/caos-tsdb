defmodule ApiStorage.Series do
  use ApiStorage.Web, :model

  @primary_key {:id, :id, autogenerate: true}
  @derive {Phoenix.Param, key: :id}
  schema "series" do
    field :project_id, :string, primary_key: true
    field :metric_name, :string, primary_key: true
    field :period, :integer, primary_key: true

    field :ttl, :integer
    field :last_timestamp, Timex.Ecto.DateTime

    timestamps()

    belongs_to :project, ApiStorage.Project,
      foreign_key: :project_id,
      references: :id,
      define_field: false

    belongs_to :metric, ApiStorage.Metric,
      foreign_key: :metric_name,
      references: :name,
      define_field: false
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:id, :project_id, :metric_name, :period, :ttl, :last_timestamp])
    |> validate_required([:project_id, :metric_name, :period])
    |> validate_immutable(:id)
    |> validate_immutable(:project_id)
    |> validate_immutable(:metric_name)
    |> foreign_key_constraint(:project_id)
    |> foreign_key_constraint(:metric_name)
    |> assoc_constraint(:project)
    |> assoc_constraint(:metric)
    |> unique_constraint(:project_id, name: "series_project_id_metric_name_period_index")
  end
end
