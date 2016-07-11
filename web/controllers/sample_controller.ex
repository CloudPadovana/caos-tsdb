defmodule ApiStorage.SampleController do
  use ApiStorage.Web, :controller

  alias ApiStorage.Sample
  alias ApiStorage.Project

  def show(conn, %{"series_id" => series_id}) do
    sample = Repo.get_by!(Sample, series_id: series_id)
    render(conn, "show.json", sample: sample)
  end

  def create(conn, %{"sample" => sample_params}) do
    changeset = Sample.changeset(%Sample{}, sample_params |> Map.update!("timestamp", &(&1 |> parse_date)))

    case Repo.insert(changeset) do
      {:ok, sample} ->
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
