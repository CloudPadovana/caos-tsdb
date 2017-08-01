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

export CAOS_TSDB_RELEASE_VERSION=$(ci-tools/git-semver.sh)
export CAOS_TSDB_RELEASE_GIT_VERSION=$(ci-tools/git-describe.sh)

if [ -z ${CAOS_TSDB_RELEASE_VERSION} ] ; then
    die "CAOS_TSDB_RELEASE_VERSION not set."
fi

if [ -z ${CAOS_TSDB_RELEASE_GIT_VERSION} ] ; then
    die "CAOS_TSDB_RELEASE_GIT_VERSION not set."
fi

if [ ${DO_DOCKER_PUSH} == true ] ; then
    say_yellow  "docker login"
    docker login -u ${CI_REGISTRY_USER} -p ${CI_REGISTRY_PASSWORD} ${CI_REGISTRY}
fi

CAOS_TSDB_DOCKER_IMAGE_TAG=${CI_REGISTRY_IMAGE}:${CAOS_TSDB_RELEASE_GIT_VERSION}

say_yellow  "Building docker container"
docker build \
       --tag ${CAOS_TSDB_DOCKER_IMAGE_TAG} \
       --build-arg RELEASE_FILE="${CI_PROJECT_DIR}/caos_tsdb-${CAOS_TSDB_RELEASE_VERSION}.tar.gz" \
       --pull=true .

if [ ${DO_DOCKER_PUSH} == true ] ; then
    say_yellow "Pushing container"
    docker push ${CAOS_TSDB_DOCKER_IMAGE_TAG}
fi
