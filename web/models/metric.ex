defmodule ApiStorage.Metric do
  use ApiStorage.Web, :model

  @primary_key {:name, :string, []}
  @derive {Phoenix.Param, key: :name}
  schema "metrics" do
    field :type, :string

    timestamps()

    has_many :series, ApiStorage.Series,
      foreign_key: :metric_name,
      references: :name
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :type])
    |> validate_required(:name)
    |> validate_immutable(:name)
  end
end
