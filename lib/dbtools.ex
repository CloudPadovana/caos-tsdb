# This file is based on the gist https://gist.github.com/jwarlander/809deb2bb06c2c43abafd471591b2dea

defmodule :dbtools do
  @moduledoc ~S"""
  Mix is not available in a built release. Instead we define the tasks here,
  and invoke it using the application script generated in the release:

      bin/caos_api command dbtools check
      bin/caos_api command dbtools migrate
  """

  def migrate do
    repo = start_repo()
    path = ensure_migrations_path(repo)
    info "Executing migrations for #{inspect repo} in #{path}:"

    migrator = &Ecto.Migrator.run/4

    {:ok, pid} = ensure_started(repo)
    migrated = migrator.(repo, path, :up, all: true)
    pid && repo.stop(pid)
    info "Applied versions: #{inspect migrated}"
    System.halt(0)
  end

  def check do
    repo = start_repo()
    info "Checking migration status for #{inspect repo}.."

    migrations = &Ecto.Migrator.migrations/2

    path = ensure_migrations_path(repo)
    {:ok, pid} = ensure_started(repo)
    repo_status = migrations.(repo, path)
    pid && repo.stop(pid)

    info """
    Repo: #{inspect repo}

    Status    Migration ID    Migration Name
    --------------------------------------------------
    """ <>
      Enum.map_join(repo_status, "\n", fn({status, number, description}) ->
        status =
          case status do
            :up   -> "up  "
            :down -> "down"
          end
        "  #{status}      #{number}  #{description}"
      end) <> "\n"
    System.halt(0)
  end

  defp start_applications(apps) do
    Enum.each(apps, fn app ->
      {:ok, _} = Application.ensure_all_started(app)
    end)
  end

  defp start_repo do
    :ok = load_app()
    [repo] = Application.get_env(:caos_api, :ecto_repos)
    {:ok, _} = repo.start_link()
    repo
  end

  defp load_app do
    start_applications([:logger, :mariaex, :ecto])
    :ok = Application.load(:caos_api)
  end

  defp ensure_migrations_path(repo) do
    path = Application.app_dir(:caos_api, "priv/repo/migrations")
    case File.dir?(path) do
      true ->
        path
      _ ->
        fatal "Could not find migrations directory #{inspect path} for repo #{inspect repo}"
    end
  end

  defp ensure_started(repo) do
    {:ok, _} = repo.__adapter__.ensure_all_started(repo, :temporary)

    case repo.start_link(pool_size: 1) do
      {:ok, pid} ->
        {:ok, pid}
      {:error, {:already_started, _pid}} ->
        {:ok, nil}
      {:error, error} ->
        fatal "Could not start repo #{inspect repo}, error: #{inspect error}"
    end
  end

  defp info(message) do
    IO.puts(message)
  end

  defp fatal(message) do
    IO.puts :stderr, message
    System.halt(1)
  end
end
