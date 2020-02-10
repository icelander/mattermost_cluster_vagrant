#!/bin/bash

mm_password=$1
master_host=$2

cd /opt/mattermost/bin
./mattermost config migrate /opt/mattermost/config/config.json "mysql://mmuser:$mm_password@tcp($master_host:3306)/mattermost?charset=utf8mb4,utf8"

