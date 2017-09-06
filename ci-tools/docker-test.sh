#!/usr/bin/env bash

################################################################################
#
# caos-tsdb - CAOS Time-Series DB
#
# Copyright © 2017 INFN - Istituto Nazionale di Fisica Nucleare (Italy)
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

set -e

source ${CI_PROJECT_DIR}/ci-tools/common.sh

export_version_vars

docker_login

DB_NAME=db_caos_docker_test

say_yellow  "Starting MySQL container"
docker run --name mysql_server -d \
       -e MYSQL_ALLOW_EMPTY_PASSWORD="yes" \
       -e MYSQL_ROOT_HOST="172.18.0.%" \
       -e MYSQL_DATABASE="$DB_NAME" \
       mysql/mysql-server:5.7
mysql_server_ip=$(docker inspect mysql_server --format '{{ .NetworkSettings.IPAddress }}')

CAOS_TSDB_DOCKER_IMAGE_TAG=${CI_REGISTRY_IMAGE}:${CAOS_TSDB_RELEASE_GIT_VERSION}

say_yellow  "Pulling docker container"
docker pull ${CAOS_TSDB_DOCKER_IMAGE_TAG}-test

say_yellow  "Waiting for MySQL"
RETRIES=0
until docker exec mysql_server mysql -h ${mysql_server_ip} -u root -e ';' ${DB_NAME} || [ ${RETRIES} -eq 5 ] ; do
    sleep 5
    RETRIES=$(( RETRIES + 1))
done
docker exec mysql_server mysql -h ${mysql_server_ip} -u root -e "SHOW CREATE DATABASE ${DB_NAME};" ${DB_NAME}

say_yellow  "Running DB migrations"
docker run --rm \
       -e CAOS_TSDB_DB_HOSTNAME=${mysql_server_ip} \
       -e CAOS_TSDB_DB_NAME=${DB_NAME} \
       -e CAOS_TSDB_DB_USERNAME=root \
       ${CAOS_TSDB_DOCKER_IMAGE_TAG}-test migrate

say_yellow  "Running docker container"
docker run -d --name caos-tsdb-test \
       -e CAOS_TSDB_PORT=8080 \
       -e CAOS_TSDB_DB_HOSTNAME=${mysql_server_ip} \
       -e CAOS_TSDB_DB_NAME=${DB_NAME} \
       -e CAOS_TSDB_DB_USERNAME=root \
       ${CAOS_TSDB_DOCKER_IMAGE_TAG}-test foreground
caos_tsdb_ip=$(docker inspect caos-tsdb-test --format '{{ .NetworkSettings.IPAddress }}')

sleep 10

docker logs caos-tsdb-test

say_yellow  "Running tests"
docker run --rm \
       -v "$PWD":/test \
       -w /test \
       python:2.7 /bin/bash -c "pip install --no-cache-dir requests && python ci-tools/test_remote_api.py http://${caos_tsdb_ip}:8080/api"

say_yellow  "Cleanup"
docker rm -f caos-tsdb-test
docker rm -f mysql_server
