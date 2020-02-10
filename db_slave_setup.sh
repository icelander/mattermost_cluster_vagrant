#!/bin/bash

ip_addr=$1
server_id=$2
root_password=$3

cat /vagrant/hosts >> /etc/hosts

apt-get -q -y update
apt-get -q -y upgrade

# Sets the root password for MariaDB
export DEBIAN_FRONTEND=noninteractive
debconf-set-selections <<< "mysql-server mysql-server/root_password password $root_password"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $root_password"
apt-get -q -y install mysql-server

# Allows cluster to connect to MySQL
sed -i 's|bind-address|#bind-address|g' /etc/mysql/mysql.conf.d/mysqld.cnf
cat /vagrant/slave.mysqld.cnf >> /etc/mysql/mysql.conf.d/mysqld.cnf
sed -i "s|#SERVER_ID|$server_id|g" /etc/mysql/mysql.conf.d/mysqld.cnf

sudo service mysql restart

mysql -uroot -proot < /vagrant/db_setup.sql

DB=mattermost
DUMP_FILE="/vagrant/$DB-export-$(date +"%Y%m%d").sql"

MASTER_USER=root
MASTER_PASS=$root_password

USER=mmuser
PASS=really_secure_password

MASTER_HOST=$master_host

echo "SLAVE: $ip_addr"
echo "  - Creating database copy"
mysql "-u$MASTER_USER" "-p$MASTER_PASS" -e "DROP DATABASE IF EXISTS $DB; CREATE DATABASE $DB;"

mysql "-u$MASTER_USER" "-p$MASTER_PASS" $DB < $DUMP_FILE

echo "  - Setting up slave replication"
mysql "-u$MASTER_USER" "-p$MASTER_PASS" $DB < /vagrant/slave_setup.sql
# Wait for slave to get started and have the correct status
sleep 2
# Check if replication status is OK
SLAVE_OK=$(mysql "-u$MASTER_USER" "-p$MASTER_PASS" -e "SHOW SLAVE STATUS\G;" | grep 'Waiting for master')
if [ -z "$SLAVE_OK" ]; then
	echo "  - Error ! Wrong slave IO state."
else
	echo "  - Slave IO state OK"
fi