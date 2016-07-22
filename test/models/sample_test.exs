defmodule CaosApi.SampleTest do
  use CaosApi.ModelCase

  alias CaosApi.Sample
  alias CaosApi.Series
  use Timex
  @series %Series{id: 1,
                  project_id: "an id",
                  metric_name: "a name",
                  period: 3600,
                  ttl: 500}

  @valid_attrs %{series_id: @series.id,
                 timestamp: DateTime.now,
                 value: 322.3}
  @sample struct(Sample, @valid_attrs)


  test "changeset with valid attributes" do
    changeset = Sample.changeset(%Sample{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Sample.changeset(%Sample{}, %{series_id: 22})
    refute changeset.valid?
  end

  test "changeset with valid change" do
    changeset = Sample.changeset(@sample, %{})
    assert changeset.valid?
  end

  test "changeset with invalid change" do
    changeset = Sample.changeset(@sample, %{value: 24.3})
    refute changeset.valid?
  end
end
