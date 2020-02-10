require 'json'

MASTER_IP = '192.168.33.101'
MASTER_HOSTNAME = 'haproxy'
MATTERMOST_VERSION = '5.18.1'

APP_SERVER_IPS = ['192.168.33.104', '192.168.33.105']
MYSQL_REPLICA_IPS = []
JOB_SERVER_IPS = []

MATTERMOST_CLUSTER_PREFIX = 'mattermost'
MYSQL_REPLICA_PREFIX = 'mysql'
JOB_SERVER_PREFIX = 'mattermostjob'

MYSQL_ROOT_PASSWORD = 'root'
MATTERMOST_PASSWORD = 'really_secure_password'

ENABLE_LDAP = true

def generate_sql_uri(host, password)
  return "mmuser:#{password}@tcp(#{host}:3306)/mattermost?charset=utf8mb4,utf8&readTimeout=30s&writeTimeout=30s"
end

config_json = File.read('config.json')
@instance_config = JSON.parse(config_json)
@instance_config["SqlSettings"] = {"DataSource" => generate_sql_uri(MASTER_HOSTNAME, MATTERMOST_PASSWORD), "DataSourceReplicas" => [], "DataSourceSearchReplicas" => []}

# mmuser:really_secure_password@tcp(haproxy:3306)/mattermost?charset=utf8mb4,utf8\u0026readTimeout=30s\u0026writeTimeout=30s

# Override the default router https://www.vagrantup.com/docs/networking/public_network.html#default-router
Vagrant.configure("2") do |config|
	config.vm.box = "bento/ubuntu-18.04"

	# Generate a hosts file based on the clusters
	hosts = Array.new
	hosts << "#{MASTER_IP}   #{MASTER_HOSTNAME}"

  	config.vm.define MASTER_HOSTNAME do |box|
		box.vm.hostname = MASTER_HOSTNAME
		box.vm.network :private_network, ip: MASTER_IP
		box.vm.network "forwarded_port", guest: 3306, host: 23306
		box.vm.network "forwarded_port", guest: 80, host: 8080
		box.vm.network "forwarded_port", guest: 9000, host: 9000

    	if ENABLE_LDAP
      		box.vm.provision "docker" do |d|
        		d.pull_images "rroemhild/test-openldap"
        		d.run "rroemhild/test-openldap",
          		args: "--privileged -d -p 389:389"
      		end
      	@instance_config['LdapSettings']['Enable'] = true
    end

		box.vm.provision :shell, path: 'setup.sh'
		box.vm.provision :shell, path: 'replication-setup.sh', run: 'always'
	end


	node_ips = MYSQL_REPLICA_IPS

	node_ips.each_with_index do |node_ip, index|
		box_hostname = "#{MYSQL_REPLICA_PREFIX}#{index}"
		hosts << "#{node_ip}   #{box_hostname}"

    @instance_config['SqlSettings']['DataSourceReplicas'].push(generate_sql_uri(box_hostname, MATTERMOST_PASSWORD))
		
		config.vm.define box_hostname do |box|
			box.vm.hostname = box_hostname
			setup_script = File.read('db_slave_setup.sh')

			setup_script.gsub! '#IP_ADDR#', node_ip
			setup_script.gsub! '#SERVER_ID#', (index+2).to_s()

			box.vm.network "forwarded_port", guest: 3306, host: "#{index+3}3306".to_i()
			box.vm.network :private_network, ip: node_ip
			box.vm.provision :shell, inline: setup_script
		end
	end

  	data_config = @instance_config.to_json
  	f = File.open('instance_config.json', 'w')
  	f.write(data_config.gsub("&", "\\u0026"))
  	f.close

  	node_ips = JOB_SERVER_IPS

  	node_ips.each_with_index do |node_ip, index|
    	box_hostname = "#{JOB_SERVER_PREFIX}#{index}"
    	hosts << "#{node_ip}   #{box_hostname}"

    	config.vm.define box_hostname do |box|
      		box.vm.hostname = box_hostname
		    box.vm.network :private_network, ip: node_ip
      		box.vm.provision :shell, path: "mattermost_setup.sh", args: [MATTERMOST_VERSION, "job", node_ip]
    	end
  	end
  	
	node_ips = APP_SERVER_IPS

	node_ips.each_with_index do |node_ip, index|
		box_hostname = "#{MATTERMOST_CLUSTER_PREFIX}#{index}"
		hosts << "#{node_ip}   #{box_hostname}"

		config.vm.define box_hostname do |box|
			box.vm.hostname = box_hostname

			box.vm.network :private_network, ip: node_ip
			box.vm.network "forwarded_port", guest: 8065, host: "#{index+1}8065".to_i()

    		type = "mattermost"
      		if JOB_SERVER_IPS.length > 0
        		type = "app"
      		end

			box.vm.provision :shell, path: "mattermost_setup.sh", args: [MATTERMOST_VERSION, type, node_ip]

			if index == node_ips.size - 1
				box.vm.provision :shell, path: 'mattermost_finalize.sh'
			end
		end
	end

	hosts_file = File.open('hosts', 'w')
	hosts_file.write(hosts.join("\n"))
	hosts_file.close
end