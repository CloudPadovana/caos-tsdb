defmodule CaosApi.Router do
  use CaosApi.Web, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :api_auth do
    plug Guardian.Plug.VerifyHeader, realm: "Bearer"
    plug Guardian.Plug.LoadResource
    plug Guardian.Plug.EnsureAuthenticated, handler: CaosApi.AuthErrorHandler
  end

  scope "/api", CaosApi do
    pipe_through [:api]

    resources "/token", TokenController, only: [:show], singleton: true
  end

  scope "/api", CaosApi do
    pipe_through [:api, :api_auth]

    resources "/projects", ProjectController, param: "id", except: [:new, :edit, :delete]
    resources "/metrics", MetricController, param: "name", except: [:new, :edit, :delete]

    resources "/series", SeriesController, param: "id", except: [:new, :edit, :delete] do
      get "/grid", SeriesController, :grid, as: "grid"
      get "/samples", SampleController, :show, as: "samples"
    end

    resources "/samples", SampleController, only: [:show, :create], singleton: true

    resources "/aggregate", AggregateController, only: [:show], singleton: true
  end
end
