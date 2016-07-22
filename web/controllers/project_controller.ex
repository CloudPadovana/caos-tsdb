defmodule CaosApi.ProjectController do
  use CaosApi.Web, :controller

  alias CaosApi.Project

  def index(conn, _params) do
    projects = Repo.all(Project)
    render(conn, "index.json", projects: projects)
  end

  def create(conn, %{"project" => project_params}) do
    changeset = Project.changeset(%Project{}, project_params)

    case Repo.insert(changeset) do
      {:ok, project} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", project_path(conn, :show, project))
        |> render("show.json", project: project)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(CaosApi.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    project = Repo.get(Project, id)
    if project do
      render(conn, "show.json", project: project)
    else
      conn
      |> put_status(:not_found)
      |> render(CaosApi.ErrorView, "404.json")
    end
  end

  def update(conn, %{"id" => id, "project" => project_params}) do
    project = Repo.get!(Project, id)
    changeset = Project.changeset(project, project_params)

    case Repo.update(changeset) do
      {:ok, project} ->
        render(conn, "show.json", project: project)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(CaosApi.ChangesetView, "error.json", changeset: changeset)
    end
  end
end
