# CaosTsdb

## How to start development

  1. Setup VM with `vagrant up && vagrant ssh`
  2. Install dependencies with `mix deps.get`
  3. Create and migrate your database with `mix ecto.create && mix ecto.migrate`
  4. Start Phoenix endpoint with `mix phoenix.server`

The API is exposed at [`localhost:4000/api`](http://localhost:4000/api).

## How to build a release

Releases can be made by using the script `build_release.sh`, which
builds a release for HEAD. It will generate the file
`releases/caos-tsdb-<version>.tar.gz` containing the binary distribution.

The script `build_docker.sh` generates a minimal docker image to be used
for deployment.

## How to run in production

To run the container:
```
docker run -p 8080:80 --name caos-tsdb \
    -v <path to caos_tsdb.conf>:/etc/caos/caos-tsdb.conf:ro \
    caos-tsdb[:<tag>] <command>
```

Check and update the DB with:
  - `command dbtools check`
  - `command dbtools migrate`

Start the server with `start`.
