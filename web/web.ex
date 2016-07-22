defmodule CaosApi.Web do
  @moduledoc """
  A module that keeps using definitions for controllers,
  views and so on.

  This can be used in your application as:

      use CaosApi.Web, :controller
      use CaosApi.Web, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below.
  """

  def model do
    quote do
      use Ecto.Schema
      use Timex.Ecto.Timestamps

      import Ecto
      import Ecto.Changeset
      import Ecto.Query

      import CaosApi.Models.Helpers
    end
  end

  def controller do
    quote do
      use Phoenix.Controller

      alias CaosApi.Repo
      import Ecto
      import Ecto.Query

      import CaosApi.Router.Helpers
      import CaosApi.Gettext
      import CaosApi.DateTime.Helpers
      import CaosApi.QueryFilter
    end
  end

  def view do
    quote do
      use Phoenix.View, root: "web/templates"

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_csrf_token: 0, get_flash: 2, view_module: 1]

      import CaosApi.Router.Helpers
      import CaosApi.ErrorHelpers
      import CaosApi.Gettext
      import CaosApi.DateTime.Helpers
    end
  end

  def router do
    quote do
      use Phoenix.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel

      alias CaosApi.Repo
      import Ecto
      import Ecto.Query
      import CaosApi.Gettext
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
