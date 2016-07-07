defmodule ApiStorage.ProjectView do
  use ApiStorage.Web, :view

  def render("index.json", %{projects: projects}) do
    %{data: render_many(projects, ApiStorage.ProjectView, "project.json")}
  end

  def render("show.json", %{project: project}) do
    %{data: render_one(project, ApiStorage.ProjectView, "project.json")}
  end

  def render("project.json", %{project: project}) do
    %{id: project.id,
      name: project.name}
  end
end
