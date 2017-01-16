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

defmodule CaosTsdb.TagController do
  use CaosTsdb.Web, :controller

  alias CaosTsdb.Tag

  def index(conn, params) do
    tags = Tag
    |> CaosTsdb.QueryFilter.filter(%Tag{}, params, [:id, :key, :value])
    |> Repo.all

    render(conn, "index.json", tags: tags)
  end

  def create(conn, %{"tag" => tag_params}) do
    changeset = Tag.changeset(%Tag{}, tag_params)

    case Repo.insert(changeset) do
      {:ok, tag} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", tag_path(conn, :show, tag))
        |> render("show.json", tag: tag)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(CaosTsdb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    tag = Repo.get_by(Tag, id: id)

    if tag do
      render(conn, "show.json", tag: tag)
    else
      conn
      |> put_status(:not_found)
      |> render(CaosTsdb.ErrorView, "404.json")
    end
  end

  def update(conn, %{"id" => id, "tag" => tag_params}) do
    tag = Repo.get_by(Tag, id: id)
    changeset = Tag.changeset(tag, tag_params)

    case Repo.update(changeset) do
      {:ok, tag} ->
        render(conn, "show.json", tag: tag)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(CaosTsdb.ChangesetView, "error.json", changeset: changeset)
    end
  end
end
