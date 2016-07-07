defmodule ApiStorage.Sample do
  use ApiStorage.Web, :model

  @primary_key false
  schema "samples" do
    field :project_id, :string, primary_key: true
    field :name, :string, primary_key: true
    field :value, :float

    timestamps()

    belongs_to :project, ApiStorage.Project,
      foreign_key: :project_id,
      references: :id,
      define_field: false
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:project_id, :name, :value])
    |> validate_required([:project_id, :name])
  end
end
