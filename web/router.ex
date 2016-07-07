defmodule ApiStorage.Router do
  use ApiStorage.Web, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", ApiStorage do
    pipe_through :api

    resources "/projects", ProjectController, except: [:new, :edit, :delete]

    resources "/samples", SampleController, only: [:show, :create], singleton: true
  end
end
