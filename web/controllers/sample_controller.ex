defmodule ApiStorage.SampleController do
  use ApiStorage.Web, :controller

  alias ApiStorage.Sample
  alias ApiStorage.Series

  plug :scrub_datetime, "timestamp"

  def show(conn, params) do
    samples = Sample
    |> ApiStorage.QueryFilter.filter(%Sample{}, params, [:series_id, :timestamp])
    |> Repo.all

    render(conn, "show.json", samples: samples)
  end

  def create(conn, %{"sample" => sample_params}) do
    changeset = Sample.changeset(%Sample{}, sample_params)

    case Repo.insert(changeset) do
      {:ok, sample} ->

        last_timestamp =
        (from s in Sample,
          where: s.series_id == ^sample.series_id)
        |> Repo.aggregate(:max, :timestamp)

        series = Repo.get_by!(Series, id: sample.series_id)
        changeset = Series.changeset(series, %{"last_timestamp" => last_timestamp})

        case Repo.update(changeset) do
          {:ok, _} -> nil
          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> render(ApiStorage.ChangesetView, "error.json", changeset: changeset)
        end

        conn
        |> put_status(:created)
        |> put_resp_header("location", sample_path(conn, :show, %{"series_id" => sample.series_id, "timestamp" => sample.timestamp |> format_date}))
        |> render("show.json", sample: sample)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ApiStorage.ChangesetView, "error.json", changeset: changeset)
    end
  end
end
