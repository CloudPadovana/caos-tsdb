# CaosTsdb

## How to start development

  1. Setup VM with `vagrant up && vagrant ssh`
  2. Install dependencies with `mix deps.get`
  3. Create and migrate your database with `mix ecto.create && mix ecto.migrate`
  4. Start Phoenix endpoint with `mix phoenix.server`

The API is exposed at [`localhost:4000/api`](http://localhost:4000/api).

## How to build a release

Releases can be made by using the script `build_release.sh`. To make a
release for HEAD just run `build_release.sh` without arguments. It will
generate two `.tar.gz` archive under the `releases` directory: a
`caos-tsdb-src-<version>.tar.gz` (made through `git archive`) and a
`caos-tsdb-<version>.tar.gz` containing binary distribution.

The same script can be used to generate a release for a tag or commit
different from HEAD by using the `-t` argument: `build_release.sh -t
<tag>` or `build_release.sh -t <commit>`.

At the end the script generates also a minimal docker image to be used
for deployment.

## How to run in production

Generate a release with the `build_release.sh` script and push the
image. To run the container:
```
docker run -p 8080:80 --name caos-tsdb \
    -v <path to caos_tsdb.conf>:/caos-tsdb/caos_tsdb.conf:ro \
    caos-tsdb[:<tag>] <command>
```

Check and update the DB with:
  - `command dbtools check`
  - `command dbtools migrate`

Start the server with `start`.
