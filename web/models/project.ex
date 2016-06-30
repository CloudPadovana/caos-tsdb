defmodule ApiStorage.Project do
  use ApiStorage.Web, :model

  @primary_key {:project_id, :string, []}
  @derive {Phoenix.Param, key: :project_id}
  schema "projects" do
    field :name, :string

    timestamps()
  end

  @required_fields ~w(project_id)
  @optional_fields ~w(name)

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields, @optional_fields)
    |> validate_required(:project_id)
  end
end
