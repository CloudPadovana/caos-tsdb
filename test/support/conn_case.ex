################################################################################
#
# caos-tsdb - CAOS Time-Series DB
#
# Copyright © 2016, 2017 INFN - Istituto Nazionale di Fisica Nucleare (Italy)
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

defmodule CaosTsdb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build and query models.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      use Phoenix.ConnTest

      alias CaosTsdb.Repo
      import Ecto
      import Ecto.Changeset
      import Ecto.Query

      import CaosTsdb.Router.Helpers

      # The default endpoint for testing
      @endpoint CaosTsdb.Endpoint

      import CaosTsdb.Fixtures

      @spec put_token(Plug.Conn.t, String.t) :: Plug.Conn.t
      def put_token(conn, jwt) do
        conn
        |> put_req_header("authorization", "Bearer #{jwt}")
      end

      @spec put_valid_token(Plug.Conn.t, Keyword.t) :: Plug.Conn.t
      def put_valid_token(conn, params \\ []) do
        jwt = fixture(:token, params)
        conn
        |> put_token(jwt)
      end

      # The GraphQL api endpoint
      @graphql_api_endpoint "/api/v1/graphql"

      @spec graphql_query(Plug.Conn.t, Keyword.t, Map.t) :: Plug.Conn.t
      def graphql_query(conn, query, variables \\ %{}) do
        conn = post conn, @graphql_api_endpoint, query: query, variables: variables
      end

      import CaosTsdb.Test.Support.GraphqHelpers
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(CaosTsdb.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(CaosTsdb.Repo, {:shared, self()})
    end

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
