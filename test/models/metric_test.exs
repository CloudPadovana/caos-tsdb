defmodule ApiStorage.MetricTest do
  use ApiStorage.ModelCase

  alias ApiStorage.Metric

  @metric %Metric{name: "a name", type: "a type"}
  @valid_attrs %{name: "a name", type: "a new type"}

  test "changeset with valid creation" do
    changeset = Metric.changeset(%Metric{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid creation" do
    changeset = Metric.changeset(%Metric{}, %{type: "a type"})
    refute changeset.valid?
  end

  test "changeset with valid change" do
    changeset = Metric.changeset(@metric, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid change" do
    changeset = Metric.changeset(@metric, %{name: "a new name", type: "a type"})
    refute changeset.valid?
  end
end
