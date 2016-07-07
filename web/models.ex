defmodule ApiStorage.Models.Helpers do
  import Ecto.Changeset

  @spec validate_immutable(Ecto.Changeset.t, atom) :: Ecto.Changeset.t
  def validate_immutable(changeset, field) do
    validate_change changeset, field, fn _, newvalue ->
      case Map.get(changeset.data, field) do
        ^newvalue -> []
        nil -> []
        _ -> [field: "must be kept immutable"]
      end
    end
  end
end
