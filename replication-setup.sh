#!/bin/bash
DB=mattermost
DUMP_FILE="/vagrant/$DB-export-$(date +"%Y%m%d").sql"

MASTER_USER=root
MASTER_PASS=root

USER=mmuser
PASS=really_secure_password

MASTER_HOST=nginx

##
# MASTER
# ------
# Export database and read log position from master, while locked
##

echo "MASTER: $MASTER_HOST"

mysql "-u$MASTER_USER" "-p$MASTER_PASS" $DB <<-EOSQL &
	GRANT REPLICATION SLAVE ON *.* TO '$USER'@'%' IDENTIFIED BY '$PASS';
	FLUSH PRIVILEGES;
	FLUSH TABLES WITH READ LOCK;
	DO SLEEP(3600);
EOSQL

echo "  - Waiting for database to be locked"
sleep 3

# Dump the database (to the client executing this script) while it is locked
echo "  - Dumping database to $DUMP_FILE"
mysqldump "-u$MASTER_USER" "-p$MASTER_PASS" --opt $DB > $DUMP_FILE
echo "  - Dump complete."

# Take note of the master log position at the time of dump
MASTER_STATUS=$(mysql "-u$MASTER_USER" "-p$MASTER_PASS" -ANe "SHOW MASTER STATUS;" | awk '{print $1 " " $2}')
LOG_FILE=$(echo $MASTER_STATUS | cut -f1 -d ' ')
LOG_POS=$(echo $MASTER_STATUS | cut -f2 -d ' ')
echo "  - Current log file is $LOG_FILE and log position is $LOG_POS"
cat /vagrant/db_setup.sql >> /vagrant/slave_setup.sql
echo "STOP SLAVE;
	CHANGE MASTER TO MASTER_HOST='$MASTER_HOST',
	MASTER_USER='$USER',
	MASTER_PASSWORD='$PASS',
	MASTER_LOG_FILE='$LOG_FILE',
	MASTER_LOG_POS=$LOG_POS;
	START SLAVE;" > /vagrant/slave_setup.sql

# When finished, kill the background locking command to unlock
kill $! 2>/dev/null
wait $! 2>/dev/null

echo "  - Master database unlocked"