#!/bin/bash

root_password=$1

cat /vagrant/hosts >> /etc/hosts

apt-get -q -y update

# Sets the root password for MariaDB
export DEBIAN_FRONTEND=noninteractive
debconf-set-selections <<< "mysql-server mysql-server/root_password password $root_password"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $root_password"
apt-get -q -y install mysql-server haproxy nfs-kernel-server

# Allows cluster to connect to MySQL
sed -i 's|bind-address|#bind-address|g' /etc/mysql/mysql.conf.d/mysqld.cnf
cat /vagrant/master.mysqld.cnf >> /etc/mysql/mysql.conf.d/mysqld.cnf
sudo service mysql restart
# Fixed - Now using passed password
mysql -uroot -p$root_password < /vagrant/db_setup.sql

cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.orig.cfg
cp /vagrant/haproxy.cfg /etc/haproxy/haproxy.cfg
cat /vagrant/appservers >> /etc/haproxy/haproxy.cfg
service haproxy restart # Fixed: Need to restart haproxy to pick up config changes


mkdir -p /srv/nfs4/mmstdata
useradd --user-group mattermost
chown -R mattermost:mattermost /srv/nfs4/mmstdata
chmod -R 777 /srv/nfs4/mmstdata
echo "/srv/nfs4/mmstdata 192.168.33.0/24(rw,async,no_subtree_check)" >> /etc/exports
systemctl restart nfs-kernel-server