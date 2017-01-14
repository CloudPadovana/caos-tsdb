################################################################################
#
# caos-tsdb - CAOS Time-Series DB
#
# Copyright © 2016 INFN - Istituto Nazionale di Fisica Nucleare (Italy)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#
# Author: Fabrizio Chiarello <fabrizio.chiarello@pd.infn.it>
#
################################################################################

defmodule CaosTsdb.MigrationTest.MigrationCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that involve DB migrations.

  Finally, every test runs on a clean DB.
  """

  use ExUnit.CaseTemplate

  alias CaosTsdb.Repo

  using(opts) do
    target_migration = opts[:target_migration] || raise "No target_migration option given!"
    migrations_path = Application.app_dir(:caos_tsdb, "priv/repo/migrations")

    {_status, migration, description} = Ecto.Migrator.migrations(Repo, migrations_path)
    |> Enum.find(fn({_status, migration, _description}) ->
      migration == target_migration
    end)

    fname = Path.join(migrations_path, "#{migration}_#{description}.exs")
    {mod, _bin} = Code.load_file(fname) |> Enum.find(fn({mod, _bin}) ->
      function_exported?(mod, :__migration__, 0)
    end)
    {:module, module} = Code.ensure_loaded(String.to_atom("#{mod}.MigrationModels"))

    quote do
      alias CaosTsdb.Repo
      use unquote(module), :models

      import Ecto
      import Ecto.Query

      import CaosTsdb.MigrationTest.MigrationCase

      @moduletag target_migration: unquote(target_migration)
      @moduletag migrations_path: unquote(migrations_path)

      ExUnit.Case.register_attribute __ENV__, :before_migration
    end
  end

  setup context do
    migrations_path = context[:migrations_path]

    # drop db
    case Repo.__adapter__.storage_down(Repo.config) do
      :ok -> :ok
      {:error, :already_down} -> :ok
      {:error, error} -> flunk "The database for #{Repo} couldn't be dropped: #{error}"
    end

    # create db
    case Repo.__adapter__.storage_up(Repo.config) do
      :ok -> :ok
      {:error, :already_up} -> :ok
      {:error, error} -> flunk "The database for #{Repo} couldn't be created: #{error}"
    end

    unless target_migration = context[:target_migration] do
      flunk "no target_migration tag defined!"
    end

    Ecto.Migrator.migrations(Repo, migrations_path)
    |> Enum.filter(fn({_status, migration, _description}) ->
      migration <= target_migration
    end)
    |> Enum.each(fn({_status, migration, _description}) ->
      if context.registered.before_migration do
        fun = context.registered.before_migration
        fun.(migration)
      end

      Ecto.Migrator.run(Repo, migrations_path, :up, to: migration)
    end)
    :ok
  end
end
