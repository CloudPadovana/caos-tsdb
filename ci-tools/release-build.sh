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

if [ "${MIX_ENV}" != prod ] ; then
    die "MIX_ENV must be set to 'prod'."
fi

export CAOS_TSDB_RELEASE_VERSION=$(ci-tools/git-semver.sh)

if [ -z "${CAOS_TSDB_RELEASE_VERSION}" ] ; then
    die "CAOS_TSDB_RELEASE_VERSION not set."
fi

say_yellow  "Building release"
mix release --verbose

RELEASES_DIR=${CI_PROJECT_DIR}/releases
if [ ! -d "${RELEASES_DIR}" ] ; then
    say_yellow  "Creating releases directory"
    mkdir ${RELEASES_DIR}
fi

say_yellow  "Copying release file"
cp -v _build/${MIX_ENV}/rel/caos_tsdb/releases/${CAOS_TSDB_RELEASE_VERSION}/caos_tsdb.tar.gz ${RELEASES_DIR}/caos_tsdb-${CAOS_TSDB_RELEASE_VERSION}.tar.gz
