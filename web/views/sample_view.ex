defmodule ApiStorage.SampleView do
  use ApiStorage.Web, :view

  def render("show.json", %{sample: sample}) do
    %{data: render_one(sample, ApiStorage.SampleView, "sample.json")}
  end

  def render("sample.json", %{sample: sample}) do
    %{project_id: sample.project_id,
      name: sample.name,
      value: sample.value}
  end

end
