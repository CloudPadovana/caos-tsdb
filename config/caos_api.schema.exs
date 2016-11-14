################################################################################
#
# caos-api - CAOS backend
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

@moduledoc """
A schema is a keyword list which represents how to map, transform, and validate
configuration values parsed from the .conf file. The following is an explanation of
each key in the schema definition in order of appearance, and how to use them.

## Import

A list of application names (as atoms), which represent apps to load modules from
which you can then reference in your schema definition. This is how you import your
own custom Validator/Transform modules, or general utility modules for use in
validator/transform functions in the schema. For example, if you have an application
`:foo` which contains a custom Transform module, you would add it to your schema like so:

`[ import: [:foo], ..., transforms: ["myapp.some.setting": MyApp.SomeTransform]]`

## Extends

A list of application names (as atoms), which contain schemas that you want to extend
with this schema. By extending a schema, you effectively re-use definitions in the
extended schema. You may also override definitions from the extended schema by redefining them
in the extending schema. You use `:extends` like so:

`[ extends: [:foo], ... ]`

## Mappings

Mappings define how to interpret settings in the .conf when they are translated to
runtime configuration. They also define how the .conf will be generated, things like
documention, @see references, example values, etc.

See the moduledoc for `Conform.Schema.Mapping` for more details.

## Transforms

Transforms are custom functions which are executed to build the value which will be
stored at the path defined by the key. Transforms have access to the current config
state via the `Conform.Conf` module, and can use that to build complex configuration
from a combination of other config values.

See the moduledoc for `Conform.Schema.Transform` for more details and examples.

## Validators

Validators are simple functions which take two arguments, the value to be validated,
and arguments provided to the validator (used only by custom validators). A validator
checks the value, and returns `:ok` if it is valid, `{:warn, message}` if it is valid,
but should be brought to the users attention, or `{:error, message}` if it is invalid.

See the moduledoc for `Conform.Schema.Validator` for more details and examples.
"""
[
  extends: [],
  import: [],
  mappings: [
    "logger.level": [
      commented: false,
      datatype: :atom,
      default: :info,
      doc: "Logger level.",
      hidden: false,
      to: "logger.level"
    ],
    "logger.console.metadata": [
      commented: false,
      datatype: [
        list: :atom
      ],
      default: [
        :request_id
      ],
      doc: "Provide documentation for logger.console.metadata here.",
      hidden: true,
      to: "logger.console.metadata"
    ],
    "logger.console.format": [
      commented: false,
      datatype: :binary,
      default: """
      $time $metadata[$level] $message
      """,
      doc: "Provide documentation for logger.console.format here.",
      hidden: true,
      to: "logger.console.format"
    ],
    "caos_api.ecto_repos": [
      commented: false,
      datatype: [
        list: :atom
      ],
      default: [
        CaosApi.Repo
      ],
      doc: "Provide documentation for caos_api.ecto_repos here.",
      hidden: true,
      to: "caos_api.ecto_repos"
    ],
    "hostname": [
      commented: false,
      datatype: :binary,
      default: "localhost",
      doc: "Server hostname.",
      hidden: false,
      to: "caos_api.Elixir.CaosApi.Endpoint.url.host"
    ],
    "port": [
      commented: false,
      datatype: :integer,
      default: 4000,
      doc: "Server port.",
      hidden: false,
      to: "caos_api.Elixir.CaosApi.Endpoint.http.port"
    ],
    "secret_key_base": [
      commented: false,
      datatype: :binary,
      default: "SysJSKR79rwPkpOd7IE1CnaPwn/QMaCINo3wYsSBspU+ctT/fc8JXUE2Ki4FYAa/",
      doc: "Secret key.",
      hidden: false,
      to: "caos_api.Elixir.CaosApi.Endpoint.secret_key_base"
    ],
    "caos_api.Elixir.CaosApi.Endpoint.render_errors.view": [
      commented: false,
      datatype: :atom,
      default: CaosApi.ErrorView,
      doc: "Provide documentation for caos_api.Elixir.CaosApi.Endpoint.render_errors.view here.",
      hidden: true,
      to: "caos_api.Elixir.CaosApi.Endpoint.render_errors.view"
    ],
    "caos_api.Elixir.CaosApi.Endpoint.render_errors.accepts": [
      commented: false,
      datatype: [
        list: :binary
      ],
      default: [
        "json"
      ],
      doc: "Provide documentation for caos_api.Elixir.CaosApi.Endpoint.render_errors.accepts here.",
      hidden: true,
      to: "caos_api.Elixir.CaosApi.Endpoint.render_errors.accepts"
    ],
    "caos_api.Elixir.CaosApi.Endpoint.pubsub.name": [
      commented: false,
      datatype: :atom,
      default: CaosApi.PubSub,
      doc: "Provide documentation for caos_api.Elixir.CaosApi.Endpoint.pubsub.name here.",
      hidden: true,
      to: "caos_api.Elixir.CaosApi.Endpoint.pubsub.name"
    ],
    "caos_api.Elixir.CaosApi.Endpoint.pubsub.adapter": [
      commented: false,
      datatype: :atom,
      default: Phoenix.PubSub.PG2,
      doc: "Provide documentation for caos_api.Elixir.CaosApi.Endpoint.pubsub.adapter here.",
      hidden: true,
      to: "caos_api.Elixir.CaosApi.Endpoint.pubsub.adapter"
    ],
    "caos_api.Elixir.CaosApi.Endpoint.http.port": [
      commented: false,
      datatype: {:atom, :binary},
      default: {:system, "PORT"},
      doc: "Provide documentation for caos_api.Elixir.CaosApi.Endpoint.http.port here.",
      hidden: true,
      to: "caos_api.Elixir.CaosApi.Endpoint.http.port"
    ],
    "caos_api.Elixir.CaosApi.Endpoint.cache_static_manifest": [
      commented: false,
      datatype: :binary,
      default: "priv/static/manifest.json",
      doc: "Provide documentation for caos_api.Elixir.CaosApi.Endpoint.cache_static_manifest here.",
      hidden: true,
      to: "caos_api.Elixir.CaosApi.Endpoint.cache_static_manifest"
    ],
    "caos_api.Elixir.CaosApi.Endpoint.server": [
      commented: false,
      datatype: :atom,
      default: true,
      doc: "Provide documentation for caos_api.Elixir.CaosApi.Endpoint.server here.",
      hidden: true,
      to: "caos_api.Elixir.CaosApi.Endpoint.server"
    ],
    "caos_api.Elixir.CaosApi.Endpoint.root": [
      commented: false,
      datatype: :binary,
      default: ".",
      doc: "Provide documentation for caos_api.Elixir.CaosApi.Endpoint.root here.",
      hidden: true,
      to: "caos_api.Elixir.CaosApi.Endpoint.root"
    ],
    "caos_api.Elixir.CaosApi.Repo.adapter": [
      commented: false,
      datatype: :atom,
      default: Ecto.Adapters.MySQL,
      doc: "Provide documentation for caos_api.Elixir.CaosApi.Repo.adapter here.",
      hidden: true,
      to: "caos_api.Elixir.CaosApi.Repo.adapter"
    ],
    "db.username": [
      commented: false,
      datatype: :binary,
      default: "caos",
      doc: "DB username.",
      hidden: false,
      to: "caos_api.Elixir.CaosApi.Repo.username"
    ],
    "db.password": [
      commented: false,
      datatype: :binary,
      doc: "DB password.",
      hidden: false,
      to: "caos_api.Elixir.CaosApi.Repo.password"
    ],
    "db.name": [
      commented: false,
      datatype: :binary,
      default: "caos",
      doc: "DB name.",
      hidden: false,
      to: "caos_api.Elixir.CaosApi.Repo.database"
    ],
    "db.hostname": [
      commented: false,
      datatype: :binary,
      default: "localhost",
      doc: "DB host.",
      hidden: false,
      to: "caos_api.Elixir.CaosApi.Repo.hostname"
    ],
    "db.port": [
      commented: false,
      datatype: :integer,
      default: 3306,
      doc: "DB port.",
      hidden: false,
      to: "caos_api.Elixir.CaosApi.Repo.port"
    ],
    "db.pool_size": [
      commented: false,
      datatype: :integer,
      default: 1,
      doc: "DB connection pool size.",
      hidden: false,
      to: "caos_api.Elixir.CaosApi.Repo.pool_size"
    ],
    "auth.token_ttl": [
      commented: false,
      datatype: :integer,
      default: 86400,
      doc: "Token TTL in seconds.",
      hidden: false,
      to: "guardian.Elixir.Guardian.ttl"
    ],
    "auth.secret_key": [
      commented: false,
      datatype: :binary,
      default: "vUczE4q9U0SF2eQIUTMJvw==",
      doc: "Token secret key.",
      hidden: false,
      to: "guardian.Elixir.Guardian.secret_key"
    ],
    "auth.identity.username": [
      commented: false,
      datatype: :binary,
      default: "admin",
      doc: "Username",
      hidden: false,
      to: "caos_api.Elixir.Auth.identity.username"
    ],
    "auth.identity.password": [
      commented: false,
      datatype: :binary,
      default: "ADMIN_PASS",
      doc: "Password",
      hidden: false,
      to: "caos_api.Elixir.Auth.identity.password"
    ],
  ],
  transforms: [
    "guardian.Elixir.Guardian.ttl": fn conf ->
      conf
      |> Conform.Conf.get("guardian.Elixir.Guardian.ttl")
      |> Enum.map(fn {key, ttl} -> { ttl, :seconds } end)
      |> List.last
    end,
  ],
  validators: []
]
