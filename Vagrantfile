#!/usr/bin/env ruby
# encoding: utf-8

######################################################################
#
# Filename: Vagrantfile
# Created: 2016-07-25T09:10:57+0200
# Time-stamp: <2016-09-14T16:38:09cest>
# Author: Fabrizio Chiarello <fabrizio.chiarello@pd.infn.it>
#
# Copyright © 2016 by Fabrizio Chiarello
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

  config.vm.hostname = "api.caos.vagrant.local"

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
  wget https://github.com/elixir-lang/elixir/releases/download/v1.3.2/Precompiled.zip
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

