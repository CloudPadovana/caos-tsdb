defmodule ApiStorage.MetricController do
  use ApiStorage.Web, :controller

  alias ApiStorage.Metric

  def index(conn, _params) do
    metrics = Repo.all(Metric)
    render(conn, "index.json", metrics: metrics)
  end

  def create(conn, %{"metric" => metric_params}) do
    changeset = Metric.changeset(%Metric{}, metric_params)

    case Repo.insert(changeset) do
      {:ok, metric} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", metric_path(conn, :show, metric))
        |> render("show.json", metric: metric)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ApiStorage.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def show(conn, %{"name" => name}) do
    metric = Repo.get(Metric, name)
    if metric do
      render(conn, "show.json", metric: metric)
    else
      conn
      |> put_status(:not_found)
      |> render(ApiStorage.ErrorView, "404.json")
    end
  end

  def update(conn, %{"name" => name, "metric" => metric_params}) do
    metric = Repo.get!(Metric, name)
    changeset = Metric.changeset(metric, metric_params)

    case Repo.update(changeset) do
      {:ok, metric} ->
        render(conn, "show.json", metric: metric)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ApiStorage.ChangesetView, "error.json", changeset: changeset)
    end
  end
end
