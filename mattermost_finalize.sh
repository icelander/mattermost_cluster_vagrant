#!/bin/bash

cd /opt/mattermost/bin
echo "Creating Mattermost user and team"

./mattermost --config "mysql://mmuser:really_secure_password@tcp(master:3306)/mattermost?charset=utf8mb4,utf8"\
	user create --email admin@planetexpress.com --username admin --password admin --system_admin
./mattermost --config "mysql://mmuser:really_secure_password@tcp(master:3306)/mattermost?charset=utf8mb4,utf8"\
	team create --name a-team --display_name "A Team" --email admin@planetexpress.com
./mattermost --config "mysql://mmuser:really_secure_password@tcp(master:3306)/mattermost?charset=utf8mb4,utf8"\
	team add a-team admin@planetexpress.com

# Clean up
rm /vagrant/hosts
rm /vagrant/instance_config.json
rm /vagrant/client_fstab
rm /vagrant/appservers