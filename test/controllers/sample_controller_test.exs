defmodule ApiStorage.SampleControllerTest do
  use ApiStorage.ConnCase

  alias ApiStorage.Sample
  alias ApiStorage.Project
  @project %Project{id: "a project id", name: "project name"}
  @sample %Sample{project_id: "a project id",
                  name: "some content",
                  value: 42.0}
  @valid_attrs %{name: "some content", project_id: "a project id", value: 42}
  @invalid_attrs %{}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "shows chosen resource", %{conn: conn} do
    sample = Repo.insert! @sample
    conn = get conn, sample_path(conn, :show, %{
          project_id: @sample.project_id,
          name: @sample.name})
    assert json_response(conn, 200)["data"] == %{
      "project_id" => sample.project_id,
      "name" => sample.name,
      "value" => sample.value}
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, sample_path(conn, :show, %{project_id: "a", name: "b"})
    end
  end

  test "creates and renders resource when data is valid", %{conn: conn} do
    Repo.insert! @project
    conn = post conn, sample_path(conn, :create), sample: @valid_attrs
    assert json_response(conn, 201)["data"]
    assert Repo.get_by(Sample, @valid_attrs)
  end
end
