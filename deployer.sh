#!/bin/bash

# Config function for controllers
file_config () {

	host_type=$1
	modify_config=$2

	echo "INFO: Copying external scripts to zabbix folder"
	sudo cp -r /home/ubuntu/repo_clone/$host_type/external_scripts/ /etc/zabbix/
	echo "INFO: Changing permissions"
	sudo chown -R zabbix:root /etc/zabbix/external_scripts/
	for file in `ls /etc/zabbix/external_scripts/`; do
		if [[ $file == *.sh ]]; then
			sudo chmod 0770 /etc/zabbix/external_scripts/$file
		fi
	done
	
	echo "INFO: Copying user parameters"
	sudo cp /home/ubuntu/repo_clone/$host_type/custom_user_parameters.conf /etc/zabbix/zabbix_agentd.d/
	
	if [ "$modify_config" == "true" ]; then
		echo "INFO: Copying config file"
		sudo cp /home/ubuntu/repo_clone/$host_type/zabbix_agentd.conf /etc/zabbix/
	fi
}

user_in_group () {
	if id -nG "$1" | grep -Fqw "$2"; then
        echo "INFO: User $1 is already a member of the $2 group"
	else
        echo "INFO: Adding user $1 to $2 group"
        sudo usermod -aG $2 $1
	fi
}

zabbix_home_dir () {
	zabbix_dir=`echo ~zabbix`

	if [ -d "$zabbix_dir" ]; then
        echo "INFO: Zabbix home directory exists"
	else
        echo "INFO: Creating zabbix home directory at $zabbix_dir"
        sudo mkdir $zabbix_dir
        echo "INFO: Changing directory ownership for $zabbix_dir"
        sudo chown zabbix:zabbix $zabbix_dir
	fi
}

hostname=`hostname`
modify_config=$1

echo "DEBUG: Hostname is $hostname"

case $hostname in
	*ctrl*)
		echo "DEBUG: Executing controller case for $hostname"
		# Run script that copies all files from controller_data folder
		user_in_group "zabbix" "lxd"
		zabbix_home_dir
		file_config "controller_data" $modify_config
	;;
	*compute*|*ocpu*)
		echo "DEBUG: Executing compute case for $hostname"
		# Run script that copies all files from compute_data folder
		file_config "compute_data" $modify_config
	;;
	*)
		echo "INFO: No zabbix scripts to be applied for host $hostname"
	;;
esac
# Restart zabbix-agent.service
echo "INFO: Restarting zabbix agent on $hostname"
sudo systemctl restart zabbix-agent.service


# Cleanup
rm -rf /home/ubuntu/repo_clone