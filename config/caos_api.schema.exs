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
    "logger.console.metadata": [
      commented: false,
      datatype: [
        list: :atom
      ],
      default: [
        :request_id
      ],
      doc: "Provide documentation for logger.console.metadata here.",
      hidden: false,
      to: "logger.console.metadata"
    ],
    "logger.console.format": [
      commented: false,
      datatype: :binary,
      default: """
      [$level] $message
      """,
      doc: "Provide documentation for logger.console.format here.",
      hidden: false,
      to: "logger.console.format"
    ],
    "phoenix.stacktrace_depth": [
      commented: false,
      datatype: :integer,
      default: 20,
      doc: "Provide documentation for phoenix.stacktrace_depth here.",
      hidden: false,
      to: "phoenix.stacktrace_depth"
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
      hidden: false,
      to: "caos_api.ecto_repos"
    ],
    "caos_api.Elixir.CaosApi.Endpoint.url.host": [
      commented: false,
      datatype: :binary,
      default: "localhost",
      doc: "Provide documentation for caos_api.Elixir.CaosApi.Endpoint.url.host here.",
      hidden: false,
      to: "caos_api.Elixir.CaosApi.Endpoint.url.host"
    ],
    "caos_api.Elixir.CaosApi.Endpoint.secret_key_base": [
      commented: false,
      datatype: :binary,
      default: "SysJSKR79rwPkpOd7IE1CnaPwn/QMaCINo3wYsSBspU+ctT/fc8JXUE2Ki4FYAa/",
      doc: "Provide documentation for caos_api.Elixir.CaosApi.Endpoint.secret_key_base here.",
      hidden: false,
      to: "caos_api.Elixir.CaosApi.Endpoint.secret_key_base"
    ],
    "caos_api.Elixir.CaosApi.Endpoint.render_errors.view": [
      commented: false,
      datatype: :atom,
      default: CaosApi.ErrorView,
      doc: "Provide documentation for caos_api.Elixir.CaosApi.Endpoint.render_errors.view here.",
      hidden: false,
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
      hidden: false,
      to: "caos_api.Elixir.CaosApi.Endpoint.render_errors.accepts"
    ],
    "caos_api.Elixir.CaosApi.Endpoint.pubsub.name": [
      commented: false,
      datatype: :atom,
      default: CaosApi.PubSub,
      doc: "Provide documentation for caos_api.Elixir.CaosApi.Endpoint.pubsub.name here.",
      hidden: false,
      to: "caos_api.Elixir.CaosApi.Endpoint.pubsub.name"
    ],
    "caos_api.Elixir.CaosApi.Endpoint.pubsub.adapter": [
      commented: false,
      datatype: :atom,
      default: Phoenix.PubSub.PG2,
      doc: "Provide documentation for caos_api.Elixir.CaosApi.Endpoint.pubsub.adapter here.",
      hidden: false,
      to: "caos_api.Elixir.CaosApi.Endpoint.pubsub.adapter"
    ],
    "caos_api.Elixir.CaosApi.Endpoint.http.port": [
      commented: false,
      datatype: :integer,
      default: 4000,
      doc: "Provide documentation for caos_api.Elixir.CaosApi.Endpoint.http.port here.",
      hidden: false,
      to: "caos_api.Elixir.CaosApi.Endpoint.http.port"
    ],
    "caos_api.Elixir.CaosApi.Endpoint.debug_errors": [
      commented: false,
      datatype: :atom,
      default: true,
      doc: "Provide documentation for caos_api.Elixir.CaosApi.Endpoint.debug_errors here.",
      hidden: false,
      to: "caos_api.Elixir.CaosApi.Endpoint.debug_errors"
    ],
    "caos_api.Elixir.CaosApi.Endpoint.code_reloader": [
      commented: false,
      datatype: :atom,
      default: true,
      doc: "Provide documentation for caos_api.Elixir.CaosApi.Endpoint.code_reloader here.",
      hidden: false,
      to: "caos_api.Elixir.CaosApi.Endpoint.code_reloader"
    ],
    "caos_api.Elixir.CaosApi.Endpoint.check_origin": [
      commented: false,
      datatype: :atom,
      default: false,
      doc: "Provide documentation for caos_api.Elixir.CaosApi.Endpoint.check_origin here.",
      hidden: false,
      to: "caos_api.Elixir.CaosApi.Endpoint.check_origin"
    ],
    "caos_api.Elixir.CaosApi.Repo.adapter": [
      commented: false,
      datatype: :atom,
      default: Ecto.Adapters.MySQL,
      doc: "Provide documentation for caos_api.Elixir.CaosApi.Repo.adapter here.",
      hidden: false,
      to: "caos_api.Elixir.CaosApi.Repo.adapter"
    ],
    "caos_api.Elixir.CaosApi.Repo.username": [
      commented: false,
      datatype: :binary,
      default: "root",
      doc: "Provide documentation for caos_api.Elixir.CaosApi.Repo.username here.",
      hidden: false,
      to: "caos_api.Elixir.CaosApi.Repo.username"
    ],
    "caos_api.Elixir.CaosApi.Repo.password": [
      commented: false,
      datatype: :binary,
      doc: "Provide documentation for caos_api.Elixir.CaosApi.Repo.password here.",
      hidden: false,
      to: "caos_api.Elixir.CaosApi.Repo.password"
    ],
    "caos_api.Elixir.CaosApi.Repo.database": [
      commented: false,
      datatype: :binary,
      default: "caos_api_dev",
      doc: "Provide documentation for caos_api.Elixir.CaosApi.Repo.database here.",
      hidden: false,
      to: "caos_api.Elixir.CaosApi.Repo.database"
    ],
    "caos_api.Elixir.CaosApi.Repo.hostname": [
      commented: false,
      datatype: :binary,
      default: "localhost",
      doc: "Provide documentation for caos_api.Elixir.CaosApi.Repo.hostname here.",
      hidden: false,
      to: "caos_api.Elixir.CaosApi.Repo.hostname"
    ],
    "caos_api.Elixir.CaosApi.Repo.pool_size": [
      commented: false,
      datatype: :integer,
      default: 10,
      doc: "Provide documentation for caos_api.Elixir.CaosApi.Repo.pool_size here.",
      hidden: false,
      to: "caos_api.Elixir.CaosApi.Repo.pool_size"
    ]
  ],
  transforms: [],
  validators: []
]