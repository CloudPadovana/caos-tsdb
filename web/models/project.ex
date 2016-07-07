defmodule ApiStorage.Project do
  use ApiStorage.Web, :model

  @primary_key {:id, :string, []}
  @derive {Phoenix.Param, key: :id}
  schema "projects" do
    field :name, :string

    timestamps()
  end

  def validate_immutable(changeset, field) do
    validate_change changeset, field, fn _, newvalue ->
      case Map.get(changeset.data, field) do
        ^newvalue -> []
        nil -> []
        _ -> [field: "must be kept immutable"]
      end
    end
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
