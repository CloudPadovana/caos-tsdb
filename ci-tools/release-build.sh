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
