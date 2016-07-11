defmodule ApiStorage.Project do
  use ApiStorage.Web, :model

  @primary_key {:id, :string, []}
  @derive {Phoenix.Param, key: :id}
  schema "projects" do
    field :name, :string

    timestamps()

    has_many :series, ApiStorage.Series,
      foreign_key: :project_id,
      references: :id
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:id, :name])
    |> validate_required(:id)
    |> validate_immutable(:id)
  end
end
