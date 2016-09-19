# CaosApi

## How to start development

  1. Setup VM with `vagrant up && vagrant ssh`
  2. Install dependencies with `mix deps.get`
  3. Create and migrate your database with `mix ecto.create && mix ecto.migrate`
  4. Start Phoenix endpoint with `mix phoenix.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## How to build for production

  1. build with `MIX_ENV=prod mix compile`
  2. generate release with `MIX_ENV=prod mix release --verbosity=verbose`
  3. deploy the release
  4. setup the release configuration in `releases/<version>/caos_api.conf`
  5. check and update the DB with:
      - `bin/caos_api command dbtools check`
      - `bin/caos_api command dbtools migrate`

  5. start the server with `bin/caos_api start`
  6. attach with `bin/caos_api attach`
