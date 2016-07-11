defmodule ApiStorage.Sample do
  use ApiStorage.Web, :model

  @primary_key false
  schema "samples" do
    field :series_id, :id, primary_key: true
    field :timestamp, Timex.Ecto.DateTime, primary_key: true
    field :value, :float

    timestamps()

    belongs_to :series, ApiStorage.Series,
      foreign_key: :series_id,
      references: :id,
      define_field: false
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:series_id, :timestamp, :value])
    |> validate_required([:series_id, :timestamp])
    |> validate_immutable(:series_id)
    |> validate_immutable(:timestamp)
    |> validate_immutable(:value)
    |> foreign_key_constraint(:series_id)
    |> assoc_constraint(:series)
    |> unique_constraint(:series_id, name: "samples_series_id_timestamp_index")
  end
end
