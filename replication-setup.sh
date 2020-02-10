#!/bin/bash
DB=mattermost
DUMP_FILE="/vagrant/$DB-export-$(date +"%Y%m%d").sql"

root_user="root"
root_password=$1

mm_user="mmuser"
mm_pass=$2

master_host=$3

##
# MASTER
# ------
# Export database and read log position from master, while locked
##

echo "MASTER: $MASTER_HOST"

mysql "-u$root_user" "-p$root_password" $DB <<-EOSQL &
	GRANT REPLICATION SLAVE ON *.* TO '$mm_user'@'%' IDENTIFIED BY '$mm_pass';
	FLUSH PRIVILEGES;
	FLUSH TABLES WITH READ LOCK;
	DO SLEEP(3600);
EOSQL

echo "  - Waiting for database to be locked"
sleep 3

# Dump the database (to the client executing this script) while it is locked
echo "  - Dumping database to $DUMP_FILE"
mysqldump "-u$root_user" "-p$root_password" --opt $DB > $DUMP_FILE
echo "  - Dump complete."

# Take note of the master log position at the time of dump
master_status=$(mysql "-u$root_user" "-p$root_password" -ANe "SHOW MASTER STATUS;" | awk '{print $1 " " $2}')
log_file=$(echo $master_status | cut -f1 -d ' ')
log_pos=$(echo $master_status | cut -f2 -d ' ')
echo "  - Current log file is $log_file and log position is $log_pos"
cat /vagrant/db_setup.sql >> /vagrant/slave_setup.sql
echo "STOP SLAVE;
	CHANGE MASTER TO MASTER_HOST='$master_host',
	MASTER_USER='$mm_user',
	MASTER_PASSWORD='$mm_pass',
	MASTER_LOG_FILE='$log_file',
	MASTER_LOG_POS=$log_pos;
	START SLAVE;" > /vagrant/slave_setup.sql

# When finished, kill the background locking command to unlock
kill $! 2>/dev/null
wait $! 2>/dev/null

echo "  - Master database unlocked"