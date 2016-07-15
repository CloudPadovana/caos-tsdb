defmodule ApiStorage.SampleView do
  use ApiStorage.Web, :view

  def render("show.json", %{samples: samples}) do
    %{data: render_many(samples, ApiStorage.SampleView, "sample.json")}
  end

  def render("show.json", %{sample: sample}) do
    %{data: render_one(sample, ApiStorage.SampleView, "sample.json")}
  end

  def render("sample.json", %{sample: sample}) do
    %{series_id: sample.series_id,
      timestamp: sample.timestamp,
      value: sample.value}
  end
end