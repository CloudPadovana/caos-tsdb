defmodule CaosApi.SeriesController do
  use CaosApi.Web, :controller

  alias CaosApi.Series

  plug :scrub_datetime, "from" when action in [:grid]

  def index(conn, params) do
    series = Series
    |> CaosApi.QueryFilter.filter(%Series{}, params, [:id, :project_id, :metric_name, :period])
    |> Repo.all

    render(conn, "index.json", series: series)
  end

  def create(conn, %{"series" => series_params}) do
    changeset = Series.changeset(%Series{}, series_params)

    case Repo.insert(changeset) do
      {:ok, series} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", series_path(conn, :show, series))
        |> render("show.json", series: series)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(CaosApi.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    series = Repo.get_by!(Series, id: id)
    render(conn, "show.json", series: series)
  end

  def update(conn, %{"id" => id, "series" => series_params}) do
    series = Repo.get_by!(Series, id: id)
    changeset = Series.changeset(series, series_params)

    case Repo.update(changeset) do
      {:ok, series} ->
        render(conn, "show.json", series: series)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(CaosApi.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def grid(conn, %{"series_id" => id, "from" => start_date}) do
    series = Repo.get_by!(Series, id: id)
    period = series.period
    last_timestamp = series.last_timestamp

    to = Timex.DateTime.now

    d = Timex.diff(Timex.DateTime.epoch, start_date)
    n = trunc(d / period)

    from = Timex.DateTime.epoch
    |> Timex.shift(seconds: n*period)

    grid = Timex.Interval.new(from: from, until: to, step: [seconds: period])
    |> Enum.map(fn(x) -> format_date(x) end)

    render(conn, "grid.json", grid: grid)
  end
end
