defmodule CaosApi.Router do
  use CaosApi.Web, :router
  alias CaosApi.APIVersion

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :api_auth do
    plug Guardian.Plug.VerifyHeader, realm: "Bearer"
    plug Guardian.Plug.LoadResource
  end

  pipeline :api_auth_ensure do
    plug Guardian.Plug.EnsureAuthenticated, handler: CaosApi.AuthErrorHandler
  end

  pipeline :v1 do
    plug APIVersion, version: :v1
  end

  scope "/api/v1", CaosApi do
    pipe_through [:v1, :api, :api_auth]

    resources "/token", TokenController, only: [:show], singleton: true
    resources "/status", StatusController, only: [:index]
  end

  scope "/api/v1", CaosApi do
    pipe_through [:v1, :api, :api_auth, :api_auth_ensure]

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
