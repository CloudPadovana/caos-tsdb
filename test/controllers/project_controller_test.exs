defmodule CaosApi.ProjectControllerTest do
  use CaosApi.ConnCase

  alias CaosApi.Project
  @valid_attrs %{id: "an id", name: "a name"}
  @project struct(Project, @valid_attrs)
  @invalid_attrs %{id: "a new id", name: "a name"}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
    {:ok, conn: put_valid_token(conn)}
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, project_path(conn, :index)
    assert json_response(conn, 200)["data"] == []
  end

  test "shows chosen resource", %{conn: conn} do
    project = Repo.insert! @project
    conn = get conn, project_path(conn, :show, project)
    assert json_response(conn, 200)["data"] == %{"id" => project.id,
                                                 "name" => project.name}
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    conn = get conn, project_path(conn, :show, @project)
    assert json_response(conn, 404)["errors"] != %{}
  end

  test "creates and renders resource when data is valid", %{conn: conn} do
    conn = post conn, project_path(conn, :create), project: @valid_attrs
    assert json_response(conn, 201)["data"]["id"]
    assert Repo.get_by(Project, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, project_path(conn, :create), project: %{name: "only a name"}
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "updates and renders chosen resource when data is valid", %{conn: conn} do
    project = Repo.insert! @project
    conn = put conn, project_path(conn, :update, project), project: %{@valid_attrs | name: "a new name"}
    assert json_response(conn, 200)["data"]["id"]
    assert Repo.get_by(Project, %{@valid_attrs | name: "a new name"})
  end

  test "does not update chosen resource and renders errors when id is invalid", %{conn: conn} do
    project = Repo.insert! @project
    conn = put conn, project_path(conn, :update, project), project: @invalid_attrs
    assert json_response(conn, 422)["errors"] != %{}
  end
end
