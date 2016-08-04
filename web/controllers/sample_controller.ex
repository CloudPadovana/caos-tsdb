defmodule CaosApi.SampleController do
  use CaosApi.Web, :controller

  alias CaosApi.Sample
  alias CaosApi.Series

  plug :scrub_datetime, "timestamp"

  def show(conn, params = %{"series_id" => series_id, "timestamp" => timestamp}) do
    sample = Sample
    |> CaosApi.QueryFilter.filter(%Sample{}, params, [:series_id, :timestamp])
    |> Repo.one

    render(conn, "show.json", sample: sample)
  end

  def show(conn, params = %{"series_id" => series_id}) do
    samples = Sample
    |> CaosApi.QueryFilter.filter(%Sample{}, params, :series_id)
    |> Repo.all

    render(conn, "show.json", samples: samples)
  end

  def create(conn, %{"sample" => sample_params}) do
    sample = Sample
    |> CaosApi.QueryFilter.filter(%Sample{}, sample_params, [:series_id, :timestamp])
    |> Repo.one

    changeset = case sample do
                  nil -> Sample.changeset(%Sample{}, sample_params)
                  sample -> Sample.changeset(sample, sample_params)
                end

    result = case sample do
               nil -> Repo.insert(changeset) |> Tuple.append(:created)
               _ -> Repo.update(changeset) |> Tuple.append(:ok)
             end

    with {:ok, sample, status} <- result,
         {:ok, _} <- update_last_timestamp(sample.series_id) do

      conn
      |> put_status(status)
      |> put_resp_header("location", sample_path(conn, :show, %{"series_id" => sample.series_id, "timestamp" => sample.timestamp |> format_date!}))
      |> render("show.json", sample: sample)
    else
      {:error, changeset, _} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(CaosApi.ChangesetView, "error.json", changeset: changeset)
    end
  end

  defp update_last_timestamp(series_id) do
    last_timestamp = (from s in Sample, where: s.series_id == ^series_id)
    |> Repo.aggregate(:max, :timestamp)

    series = Repo.get_by!(Series, id: series_id)
    changeset = Series.changeset(series, %{"last_timestamp" => last_timestamp})

    Repo.update(changeset)
  end
end
