defmodule CaosApi.MetricView do
  use CaosApi.Web, :view

  def render("index.json", %{metrics: metrics}) do
    %{data: render_many(metrics, CaosApi.MetricView, "metric.json")}
  end

  def render("show.json", %{metric: metric}) do
    %{data: render_one(metric, CaosApi.MetricView, "metric.json")}
  end

  def render("metric.json", %{metric: metric}) do
    %{name: metric.name,
      type: metric.type}
  end
end
