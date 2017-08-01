#!/usr/bin/env bash

######################################################################
#
# Filename: release-build.sh
# Created: 2017-07-31T16:33:42+0200
# Author: Fabrizio Chiarello <fabrizio.chiarello@pd.infn.it>
#
# Copyright © 2017 by Fabrizio Chiarello
#
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
######################################################################

set -e

source ${CI_PROJECT_DIR}/ci-tools/common.sh

export CAOS_TSDB_RELEASE_VERSION=$(ci-tools/git-semver.sh)
export CAOS_TSDB_RELEASE_GIT_VERSION=$(ci-tools/git-describe.sh)

if [ -z "${CAOS_TSDB_RELEASE_VERSION}" ] ; then
    die "CAOS_TSDB_RELEASE_VERSION not set."
fi

if [ -z "${CAOS_TSDB_RELEASE_GIT_VERSION}" ] ; then
    die "CAOS_TSDB_RELEASE_GIT_VERSION not set."
fi

if [ "${DO_DOCKER_PUSH}" == true ] ; then
    say_yellow  "docker login"
    docker login -u ${CI_REGISTRY_USER} -p ${CI_REGISTRY_PASSWORD} ${CI_REGISTRY}
fi

CAOS_TSDB_DOCKER_IMAGE_TAG=${CI_REGISTRY_IMAGE}:${CAOS_TSDB_RELEASE_GIT_VERSION}

say_yellow  "Building docker container"
docker build \
       --tag ${CAOS_TSDB_DOCKER_IMAGE_TAG} \
       --build-arg RELEASE_FILE="${CI_PROJECT_DIR}/caos_tsdb-${CAOS_TSDB_RELEASE_VERSION}.tar.gz" \
       --pull=true .

if [ "${DO_DOCKER_PUSH}" == true ] ; then
    say_yellow "Pushing container"
    docker push ${CAOS_TSDB_DOCKER_IMAGE_TAG}
fi
