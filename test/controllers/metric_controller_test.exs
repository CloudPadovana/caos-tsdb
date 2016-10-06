defmodule CaosApi.MetricControllerTest do
  use CaosApi.ConnCase

  alias CaosApi.Metric
  @valid_attrs %{name: "a name", type: "a type"}
  @metric struct(Metric, @valid_attrs)
  @invalid_attrs %{name: "a new name", type: "a type"}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
    {:ok, conn: put_valid_token(conn)}
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, metric_path(conn, :index)
    assert json_response(conn, 200)["data"] == []
  end

  test "shows chosen resource", %{conn: conn} do
    metric = Repo.insert! @metric
    conn = get conn, metric_path(conn, :show, metric)
    assert json_response(conn, 200)["data"] == %{"name" => metric.name,
                                                 "type" => metric.type}
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    conn = get conn, metric_path(conn, :show, @metric)
    assert json_response(conn, 404)["errors"] != %{}
  end

  test "creates and renders resource when data is valid", %{conn: conn} do
    conn = post conn, metric_path(conn, :create), metric: @valid_attrs
    assert json_response(conn, 201)["data"]["name"]
    assert Repo.get_by(Metric, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, metric_path(conn, :create), metric: %{type: "only a type"}
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "updates and renders chosen resource when data is valid", %{conn: conn} do
    metric = Repo.insert! @metric
    conn = put conn, metric_path(conn, :update, metric), metric: %{@valid_attrs | type: "a new type"}
    assert json_response(conn, 200)["data"]["name"]
    assert Repo.get_by(Metric, %{@valid_attrs | type: "a new type"})
  end

  test "does not update chosen resource and renders errors when id is invalid", %{conn: conn} do
    metric = Repo.insert! @metric
    conn = put conn, metric_path(conn, :update, metric), metric: @invalid_attrs
    assert json_response(conn, 422)["errors"] != %{}
  end
end
