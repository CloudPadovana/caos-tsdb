defmodule ApiStorage.ProjectTest do
  use ApiStorage.ModelCase

  alias ApiStorage.Project

  @project %Project{id: "an id", name: "a name"}
  @valid_change %{id: "an id", name: "a new name"}
  @invalid_change %{id: "an new id", name: "a new name"}

  test "changeset with valid change" do
    changeset = Project.changeset(@project, @valid_change)
    assert changeset.valid?
  end

  test "changeset with valid creation" do
    changeset = Project.changeset(%Project{}, @valid_change)
    assert changeset.valid?
  end

  test "changeset with invalid change" do
    changeset = Project.changeset(@project, @invalid_change)
    refute changeset.valid?
  end

  test "changeset with invalid creation" do
    changeset = Project.changeset(%Project{}, %{name: "a name"})
    refute changeset.valid?
  end
end
