defmodule ApiStorage.SampleController do
  use ApiStorage.Web, :controller

  alias ApiStorage.Sample
  alias ApiStorage.Project

  plug :scrub_timestamp, "timestamp"

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

  @spec scrub_timestamp(Plug.Conn.t, String.t) :: Plug.Conn.t
  defp scrub_timestamp(conn, key) when is_binary(key) do
    with {:ok, timestamp} <- Map.fetch(conn.params, key) do
      %{conn | params: %{conn.params | key => timestamp |> parse_date}}
    end
    conn
  end
end

