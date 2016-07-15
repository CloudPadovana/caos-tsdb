defmodule ApiStorage.SeriesView do
  use ApiStorage.Web, :view

  def render("index.json", %{series: series}) do
    %{data: render_many(series, ApiStorage.SeriesView, "series.json")}
  end

  def render("show.json", %{series: series}) do
    %{data: render_one(series, ApiStorage.SeriesView, "series.json")}
  end

  def render("series.json", %{series: series}) do
    %{id: series.id,
      project_id: series.project_id,
      metric_name: series.metric_name,
      period: series.period,
      ttl: series.ttl,
      last_timestamp: series.last_timestamp}
  end

  def render("grid.json", %{grid: grid}) do
    %{data: %{grid: grid}}
  end
end
