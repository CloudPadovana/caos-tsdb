defmodule ApiStorage.SampleController do
  use ApiStorage.Web, :controller

  alias ApiStorage.Sample
  alias ApiStorage.Project

  def show(conn, %{"project_id" => project_id, "name" => name}) do
    sample = Repo.get_by!(Sample, %{project_id: project_id, name: name})
    render(conn, "show.json", sample: sample)
  end

  def create(conn, %{"sample" => sample_params}) do
    project = Repo.get!(Project, sample_params["project_id"])
    changeset = Sample.changeset(%Sample{}, sample_params)

    case Repo.insert(changeset) do
      {:ok, sample} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", sample_path(conn, :show, %{"project_id" => sample.project_id, "name" => sample.name}))
        |> render("show.json", sample: sample)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ApiStorage.ChangesetView, "error.json", changeset: changeset)
    end
  end
end
