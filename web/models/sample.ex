defmodule CaosApi.Sample do
  use CaosApi.Web, :model

  @primary_key false
  schema "samples" do
    field :series_id, :id, primary_key: true
    field :timestamp, Timex.Ecto.DateTime, primary_key: true
    field :value, :float

    timestamps()

    belongs_to :series, CaosApi.Series,
      foreign_key: :series_id,
      references: :id,
      define_field: false

    field :force, :boolean, virtual: true
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:series_id, :timestamp, :value, :force])
    |> validate_required([:series_id, :timestamp])
    |> validate_immutable(:series_id)
    |> validate_immutable_unless_forced(:timestamp, :force)
    |> validate_immutable_unless_forced(:value, :force)
    |> foreign_key_constraint(:series_id)
    |> assoc_constraint(:series)
    # the following line has this form due to mysql error format
    |> unique_constraint(:primary, name: "PRIMARY")
  end
end
