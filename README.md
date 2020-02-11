# Mattermost Cluster Vagrant

## About

This sets up a configurable Mattermost cluster of any size, with a master/slave MySQL DB replica

## How to Use

### Hardware Requirements

Because this spins up several VMs, each requiring 1GB of RAM, make sure you have at least that much per machine on the host. The default brings up three VMs - The master node and two app servers, so at least 6GB of RAM is necessary, but more is always better.

### Spinning up the VM

1. Make sure Virtualbox and Vagrant are installed
2. Check out this repository
3. Modify `Vagrantfile` to set your options
3. In the repository directory, run `vagrant up`

### Connecting to the Server

#### SSH

To access the boxes, use `vagrant ssh <hostname>`, where `<hostname>` is any of the ones listed with `vagrant status`. For example, to access the Master Node, you'd use `vagrant ssh master`.

#### Mattermost

If you ran this on your workstation, go to `http://127.0.0.1:8080`. Individual Mattermost app nodes can be accessed via `http://127.0.0.1:/{node_id}8065`, where `{node_id` is a number from 1-4.

Job nodes should be accessed via SSH.
	
 - [ ] Add instructions for AWS

#### HAProxy

If you ran this on your workstation, go to `http://127.0.0.1:9000/stats` and log in with the username and password `admin`. This will load the HAProxy web interface showing the status of the nodes in the cluster.

#### MySQL

As with the Mattermost app nodes, MySQL can be accessed via `127.0.0.1:{node_id}3306`, where `{node_id}` is a number from 1-4, with 1 being the Master Node. So to access the first MySQL replica you'd use `127.0.0.1:23306`. The `root` and `mmuser` passwords are configurable options.

## Configurable Options

 - `MASTER_IP`: IP Address of the master node, which hosts HAProxy, the MySQL Master node, the NFS server, and the option LDAP server. Default is `192.168.33.101`
 - `MASTER_HOSTNAME`: Hostname of the master node, default is `haproxy`
 - `MATTERMOST_VERSION`: The version of Mattermost to install. Default is `5.19.1`
 - `APP_SERVER_IPS`: IP addresses of Mattermost app servers. Each one will create a VM. **Maximum:** 5 Default is `["192.168.33.102", "192.168.33.103"]`
 - `MYSQL_REPLICA_IPS`: IP addresses of MySQL replica servers. Each one will create a VM. **Maximum:** 5. Default is `[]`
 - `JOB_SERVER_IPS`: IP addresses of Mattermost job servers. Each one will create a VM. Default is `[]` **Maximum:** 5. (untested)
 - `APP_SERVER_PREFIX`: Prefix for the hostnames of the Mattermost app servers. Default is `'mattermost'`
 - `MYSQL_REPLICA_PREFIX`: Prefix for the hostnames of the mysql replica servers. Default is `'mysql'`
 - `JOB_SERVER_PREFIX`:  Prefix for the hostnames of the Mattermost job servers. Default is `'mattermostjob'` (untested)
 - `MYSQL_ROOT_PASSWORD`: The root password for the MySQL instances. Default is `'mysql_root_password'`
 - `MATTERMOST_PASSWORD`: Password Mattermost uses to connect to databases. Default is `'really_secure_password'`
 - `ENABLE_LDAP`: Whether to enable LDAP. Default is `false` (untested)