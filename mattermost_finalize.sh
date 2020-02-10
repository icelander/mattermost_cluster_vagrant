#!/bin/bash

cd /opt/mattermost
bin/mattermost version

bin/mattermost user create --email admin@planetexpress.com --username admin --password admin --system_admin