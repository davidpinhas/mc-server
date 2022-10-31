#!/bin/bash

#########################################
##### Minecraft Installation Script #####
#########################################

# Install prerequisites
echo "INFO: Installing prerequisites"
sudo add-apt-repository ppa:openjdk-r/ppa -y  > /dev/null 2>&1
sudo apt update  > /dev/null 2>&1
sudo apt install apt-transport-https curl gnupg-agent ca-certificates software-properties-common -y  > /dev/null 2>&1

# Install Docker
if [ -x "$(command -v docker)" ]; then
    echo "INFO: Docker client already installed. Proceeding"
else
    echo "INFO: Installing Docker client"
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - 
	sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable" -y > /dev/null 2>&1
	sudo apt install docker-ce docker-ce-cli containerd.io -y  > /dev/null 2>&1
	sudo usermod -aG docker $USER
	newgrp docker
fi

# Starting Docker service
echo "Info: Starting and enabling Docker client"
sudo systemctl start docker > /dev/null 2>&1
sudo systemctl enable docker > /dev/null 2>&1
if [ -d "/home/$USER/minecraft-data" ] 
then
    echo "Directory /home/$USER/minecraft-data exists. This directory will be used to store the servers configuration files and data" 
else
    echo "WARN: Directory '/home/$USER/minecraft-data' does not exists."
    echo "INFO: Creating directory"
    sudo mkdir /home/$USER/minecraft-data # Creating Docker volume directory to store MC server configuration files
fi

# Running Minecraft Server as a Docker container
echo "INFO: Checking Docker container status"
if [ ! "$(docker ps -q -f name=mc-server)" ]; then
    if [ "$(docker ps -aq -f status=exited -f name=mc-server)" ]; then
        # cleanup
        sudo docker rm mc-server  > /dev/null 2>&1
        echo "INFO: Cleaned exited container"
    fi
    # run your container
    echo "INFO: Deploying Minecraft server Docker container"
    sudo docker run -d -it -p 25565:25565 --name mc-server  -e EULA=TRUE --restart unless-stopped -v /home/$USER/minecraft-data:/data itzg/minecraft-server > /dev/null 2>&1
fi
# Setting up server backup job
sudo cp mc-backup.sh /usr/bin/mc-backup.sh
echo "INFO: Minecraft server installation script finished"
