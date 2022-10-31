#!/bin/bash

#########################################
##### Minecraft Installation Script #####
#########################################
if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo "WARN: Not Sudo user. Please run as root, using the following command:"
    echo "$ sudo bash minecraft-server-install.sh"
    exit
fi

external_ip=$(dig -4 TXT +short o-o.myaddr.l.google.com @ns1.google.com)
figlet Minecraft Installation

# Install prerequisites
echo "INFO: Installing prerequisites."
if [[ $(grep -rhE ^deb /etc/apt/sources.list* | grep openjdk-r) ]]; then
    echo "INFO: OpenJDK repository already exists."
else
    echo "Adding OpenJDK repository."
    sudo add-apt-repository ppa:openjdk-r/ppa -y  > /dev/null 2>&1
fi

sudo apt update  > /dev/null 2>&1
sudo apt install apt-transport-https curl gnupg-agent ca-certificates software-properties-common figlet -y  > /dev/null 2>&1

# Install Docker
if [ -x "$(command -v docker)" ]; then
    echo "INFO: Docker client already installed. Proceeding."
else
    echo "INFO: Installing Docker client."
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - 
    if [[ $(grep -rhE ^deb /etc/apt/sources.list* | grep docker) ]]; then
        echo "INFO: Docker repository already exists."
    else
        echo "Adding Docker repository."
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable" -y > /dev/null 2>&1
    fi
	sudo apt install docker-ce docker-ce-cli containerd.io -y  > /dev/null 2>&1
	sudo usermod -aG docker $USER
	newgrp docker
fi

# Starting Docker service
echo "INFO: Starting and enabling the Docker client."
sudo systemctl start docker > /dev/null 2>&1
sudo systemctl enable docker > /dev/null 2>&1
if [ -d "/etc/mc-server/minecraft-data" ] 
then
    echo "INFO: Directory /etc/mc-server/minecraft-data exists." 
else
    echo "WARN: Directory '/etc/mc-server/minecraft-data' does not exists."
    echo "INFO: Creating directory /etc/mc-server/minecraft-data."
    sudo mkdir -p /etc/mc-server/minecraft-data # Creating Docker volume directory to store MC server configuration files
fi

# Running Minecraft Server as a Docker container
echo "INFO: Checking Docker container status."
if [ ! "$(docker ps -q -f name=mc-server)" ]; then
    if [ "$(docker ps -aq -f status=exited -f name=mc-server)" ]; then
        # cleanup
        sudo docker rm -f mc-server > /dev/null 2>&1
        echo "INFO: Cleaned exited container."
    fi
    # run your container
    echo "INFO: Deploying Minecraft server Docker container."
    sudo docker run -d -it -p 25565:25565 --name mc-server -e EULA=TRUE --restart unless-stopped -v /etc/mc-server/minecraft-data:/data itzg/minecraft-server > /dev/null 2>&1
    echo "INFO: Waiting for mc-server data files to copy from the Docker container."
    while [ $(ls -l /etc/mc-server/minecraft-data | wc -l) != 13 ]
    do
        echo "INFO:" $(ls -l /etc/mc-server/minecraft-data | wc -l) echo "out of 13 copied. Waiting 5 seconds."
        sleep 5
    done
fi
# Setting up server backup job
echo "INFO: Copying backup script to bin directory"
sudo cp mc-backup.sh /usr/bin/mc-backup.sh
echo "Setting backup script with cron"
#write out current crontab
crontab -l > mc-cron
#echo new cron into cron file
echo "0 0 * * * mc-backup.sh" >> mc-cron
#install new cron file
crontab mc-cron
echo "INFO: Successfully setup cron job to automate backups."
echo "INFO: Removing temp cron file."
rm mc-cron

echo "INFO: Minecraft server installation script finished."
echo "
##### MINECRAFT SERVER INFO #####

Minecraft server endpoint:"
echo "$(echo $external_ip | tr -d '"'):25565"
echo "
Minecraft server data location:
/etc/mc-server/minecraft-data

This directory will be used to store the servers configuration files and data.

The backup script will run everyday at 12AM."
