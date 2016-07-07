defmodule ApiStorage.SampleTest do
  use ApiStorage.ModelCase

  alias ApiStorage.Sample

  @valid_attrs %{name: "some content", project_id: "some content", value: 42}
  @invalid_attrs %{name: "some name", value: 2}

  test "changeset with valid attributes" do
    changeset = Sample.changeset(%Sample{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Sample.changeset(%Sample{}, @invalid_attrs)
    refute changeset.valid?
  end
end
