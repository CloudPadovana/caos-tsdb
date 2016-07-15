defmodule ApiStorage.Router do
  use ApiStorage.Web, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", ApiStorage do
    pipe_through :api

    resources "/projects", ProjectController, param: "id", except: [:new, :edit, :delete]
    resources "/metrics", MetricController, param: "name", except: [:new, :edit, :delete]

    resources "/series", SeriesController, param: "id", except: [:new, :edit, :delete] do
      get "/grid", SeriesController, :grid, as: "grid"
    end

    resources "/samples", SampleController, only: [:show, :create], singleton: true
  end
end
