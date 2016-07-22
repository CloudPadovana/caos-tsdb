defmodule CaosApi.SampleView do
  use CaosApi.Web, :view

  def render("show.json", %{samples: samples}) do
    %{data: render_many(samples, CaosApi.SampleView, "sample.json")}
  end

  def render("show.json", %{sample: sample}) do
    %{data: render_one(sample, CaosApi.SampleView, "sample.json")}
  end

  def render("sample.json", %{sample: sample}) do
    %{series_id: sample.series_id,
      timestamp: sample.timestamp,
      value: sample.value}
  end
end
