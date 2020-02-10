#!/bin/bash

cat /vagrant/hosts >> /etc/hosts

apt-get -q -y update

# Sets the root password for MariaDB
export DEBIAN_FRONTEND=noninteractive
debconf-set-selections <<< 'mysql-server mysql-server/root_password password root'
debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password root'
apt-get -q -y install mysql-server haproxy samba

# Allows cluster to connect to MySQL
sed -i 's|bind-address|#bind-address|g' /etc/mysql/mysql.conf.d/mysqld.cnf
cat /vagrant/master.mysqld.cnf >> /etc/mysql/mysql.conf.d/mysqld.cnf
sudo service mysql restart
mysql -uroot -proot < /vagrant/db_setup.sql

cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.orig.cfg
cp /vagrant/haproxy.cfg /etc/haproxy/haproxy.cfg

service haproxy start

mkdir -p /shared/mmst-data/{data,plugins,client_plugins}

adduser --no-create-home --disabled-password --disabled-login --gecos "" mattermost

chown -R mattermost:mattermost /shared/mmst-data
mv /etc/samba/smb.conf /etc/samba/orig.smb.conf
ln -s /vagrant/smb.conf /etc/samba/smb.conf
cat /etc/passwd | mksmbpasswd > /etc/smbpasswd
(echo samba_password; echo samba_password) | smbpasswd -a mattermost
service smbd restart