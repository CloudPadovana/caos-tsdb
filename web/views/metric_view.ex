defmodule ApiStorage.MetricView do
  use ApiStorage.Web, :view

  def render("index.json", %{metrics: metrics}) do
    %{data: render_many(metrics, ApiStorage.MetricView, "metric.json")}
  end

  def render("show.json", %{metric: metric}) do
    %{data: render_one(metric, ApiStorage.MetricView, "metric.json")}
  end

  def render("metric.json", %{metric: metric}) do
    %{name: metric.name,
      type: metric.type}
  end
end
