# CaosTsdb

## How to start development

  1. Setup VM with `vagrant up && vagrant ssh`
  2. Install dependencies with `mix deps.get`
  3. Create and migrate your database with `mix ecto.create && mix ecto.migrate`
  4. Start Phoenix endpoint with `mix phoenix.server`

The API is exposed at [`localhost:4000/api`](http://localhost:4000/api).

## How to build for production

  1. build with `MIX_ENV=prod mix compile`
  2. generate release with `MIX_ENV=prod mix release --verbose`
  3. deploy the release
  4. setup the release configuration in `releases/<version>/caos_tsdb.conf`
  5. check and update the DB with:
      - `bin/caos_tsdb command dbtools check`
      - `bin/caos_tsdb command dbtools migrate`

  5. start the server with `bin/caos_tsdb start`
  6. attach with `bin/caos_tsdb attach`
