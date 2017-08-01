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

FROM debian:stretch

LABEL maintainer "Fabrizio Chiarello <fabrizio.chiarello@pd.infn.it>"

ARG RELEASES_DIR
ARG RELEASE_FILE

WORKDIR /caos-tsdb

COPY $RELEASES_DIR/$RELEASE_FILE /

RUN tar xfvz /$RELEASE_FILE

ENV LANG=C.UTF-8

VOLUME /etc/caos
ENV CONFORM_CONF_PATH=/etc/caos/caos-tsdb.conf

ENTRYPOINT [ "bin/caos_tsdb" ]
CMD [ "--help" ]
