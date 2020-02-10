#!/bin/bash
echo "Provisioning with these arguments:"
echo $@

mattermost_version=$1
type=$2
ip_address=$3
host=$4
mattermost_password=$5

if [[ -z "$type" ]]; then
	type="mattermost"
fi

if [[ ! -d /media/mmst-data ]]; then
	cat /vagrant/hosts >> /etc/hosts

	apt-get -q -y update > /dev/null
	apt-get -q -y install jq

	mkdir -p /media/mmst-data
	cat /vagrant/client_fstab >> /etc/fstab
	mount -a
fi

# Download Mattermost
if [ ! -f /vagrant/mattermost_archives/mattermost-$mattermost_version-linux-amd64.tar.gz ]; then
    wget --quiet https://releases.mattermost.com/$mattermost_version/mattermost-$mattermost_version-linux-amd64.tar.gz
    cp mattermost-$mattermost_version-linux-amd64.tar.gz /vagrant/mattermost_archives/mattermost-$mattermost_version-linux-amd64.tar.gz
else
	cp /vagrant/mattermost_archives/mattermost-$mattermost_version-linux-amd64.tar.gz ./	
fi

rm -rf /opt/mattermost

tar -xzf mattermost*.gz
rm mattermost*.gz
mv mattermost /opt

mkdir /opt/mattermost/data

cp /vagrant/e20license.txt /opt/mattermost/license.txt
mv /opt/mattermost/config/config.json /opt/mattermost/config/config.orig.json

jq -s '.[0] * .[1]' /opt/mattermost/config/config.orig.json /vagrant/instance_config.json > ./config.json

cp ./config.json /opt/mattermost/config/config.json

useradd --system --user-group mattermost
chown -R mattermost:mattermost /opt/mattermost
chmod -R g+w /opt/mattermost

echo "MM_CONFIG=\"mysql://mmuser:$mattermost_password@tcp(master:3306)/mattermost?charset=utf8mb4,utf8\"" >> /opt/mattermost/config/mm.environment
echo "MM_CLUSTERSETTINGS_OVERRIDEHOSTNAME=\"$host\"" >> /opt/mattermost/config/mm.environment
echo "MM_CLUSTERSETTINGS_ADVERTISEADDRESS=\"$ip_address\"" >> /opt/mattermost/config/mm.environment
echo "MM_CLUSTERSETTINGS_NETWORKINTERFACE=\"$ip_address\"" >> /opt/mattermost/config/mm.environment

if [[ $type == "job" ]]; then
	cat /vagrant/mattermost_job_server.env >> /opt/mattermost/config/mm.environment
elif [[ $type == "app" ]]; then
	cat /vagrant/mattermost_app_server.env >> /opt/mattermost/config/mm.environment
fi

cp /vagrant/mattermost.service /lib/systemd/system/mattermost.service

systemctl daemon-reload
/opt/mattermost/bin/mattermost version

# datasource=`jq '.SqlSettings.DataSource' /opt/mattermost/config/config.json | sed 's/"//g'`
# /opt/mattermost/bin/mattermost config migrate  /opt/mattermost/config/config.json "mysql://$datasource"

echo "Starting Mattermost"
service mattermost start