#!/bin/bash

cd /opt/mattermost/bin
echo "Creating Mattermost user and team"

export MM_CONFIG="mysql://mmuser:really_secure_password@tcp(master:3306)/mattermost?charset=utf8mb4,utf8"
./mattermost user create --email admin@planetexpress.com --username admin --password admin --system_admin
./mattermost team create --name a-team --display_name "A Team" --email admin@planetexpress.com
./mattermost team add a-team admin@planetexpress.com

# Fix permissions
sudo chown -R mattermost:mattermost /opt/mattermost

# Clean up
rm /vagrant/hosts
rm /vagrant/instance_config.json
rm /vagrant/client_fstab
rm /vagrant/appservers