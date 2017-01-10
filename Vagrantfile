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

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.provider "virtualbox" do |v|
    v.memory = 512
    v.cpus = 2
    v.linked_clone = true
  end

  config.vm.box = "centos/7"

  config.vm.synced_folder ".", "/vagrant", disabled: true

  config.vm.synced_folder ".", "/vagrant",
                          create: true,
                          type: "virtualbox"

  # phoenix server
  config.vm.network :forwarded_port, guest: 4000, host: 4000

  config.vm.hostname = "tsdb.caos.vagrant.localhost"

  $script = <<SCRIPT
sed -i 's/AcceptEnv/# AcceptEnv/' /etc/ssh/sshd_config
localectl set-locale "LANG=en_US.utf8"
systemctl reload sshd.service

echo "cd /vagrant" >> /home/vagrant/.bash_profile

yum update -v -y
yum install -v -y epel-release wget unzip

### ERLANG
rm -f erlang-solutions-1.0-1.noarch.rpm
wget https://packages.erlang-solutions.com/erlang-solutions-1.0-1.noarch.rpm
rpm -Uvh erlang-solutions-1.0-1.noarch.rpm
yum install -v -y esl-erlang

rm -rf /opt/elixir && mkdir -p /opt/elixir
(
  cd /opt/elixir
  wget https://github.com/elixir-lang/elixir/releases/download/v1.4.0/Precompiled.zip
  unzip Precompiled.zip
)
echo 'export PATH=$PATH:/opt/elixir/bin' >> /home/vagrant/.bash_profile

### mysql
yum install -v -y mariadb-server
systemctl enable mariadb
systemctl start mariadb

SCRIPT

  config.vm.provision :shell, :inline => $script
end

