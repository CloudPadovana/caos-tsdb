#!/usr/bin/env ruby
# encoding: utf-8

################################################################################
#
# caos-tsdb - CAOS Time-Series DB
#
# Copyright © 2016, 2017 INFN - Istituto Nazionale di Fisica Nucleare (Italy)
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

VAGRANTFILE_API_VERSION = "2"

# disable parallel spawing of containers, otherwise 'vagrant up' will
# fail due to docker linking order
ENV['VAGRANT_NO_PARALLEL'] = 'yes'

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.define "caos-tsdb-db" do |db|
    db.vm.hostname = "db"
    db.vm.synced_folder ".", "/vagrant", disabled: true

    db.vm.provider :docker do |d|
      d.name = "caos-tsdb-db"
      d.has_ssh = false
      d.image = "mysql/mysql-server:5.7"
      d.create_args = [
        "-e", "MYSQL_ALLOW_EMPTY_PASSWORD=yes",
        "-e", "MYSQL_ROOT_HOST=172.17.0.%",
      ]
    end
  end

  config.vm.define "caos-tsdb", primary: true do |tsdb|
    tsdb.vm.hostname = "caos-tsdb"
    tsdb.ssh.username = "vagrant"
    tsdb.ssh.password = "vagrant"

    tsdb.vm.provider :docker do |d|
      d.name = "caos-tsdb"
      d.has_ssh = true
      d.build_dir = "."
      d.dockerfile = "Dockerfile.vagrant"
      d.build_args = [ "-t", "vagrant-caos-tsdb" ]
      d.create_args = [
        "-e", "CAOS_TSDB_DB_HOSTNAME=caos-tsdb-db",
      ]

      d.ports = [
        # phoenix server
        '4000:4000',
      ]

      d.link "caos-tsdb-db:db"
    end
  end
end
