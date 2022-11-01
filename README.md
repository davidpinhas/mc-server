![Minecraft Server](img/mc-server.png)

Install Minecraft server on ARM architecture using Oracle Cloud Infrastructure.

The server will be installed as a container using the Docker client and will retain the server's data in the directory '/home/$USER/minecraft-data', by default. 
To evert data loss when the server encounters applicative issues or data corruption, the 'mc-backup.sh' script will run on a daily basis, using a CRON job backing up the server's data to the directory '/home/$USER/minecraft-backup' and will keep 5 snapshots of the data (to modify the snapshots count, read more under 'Server Usage').

# Server Configuration
### Machine access
When creating a VM in OCI, we will have an option to generate a SSH keypair and using the private key for authentication.

To access the machine, SSH to the VM using the key for authentication:
```bash
ssh -i ~/.ssh/mc.key user@123.123.123.123
```

```bash
git clone https://github.com/davidpinhas/mc-server.git
```

### Installation
Installation script:
```bash
#!/bin/bash

#########################################
##### Minecraft Installation Script #####
#########################################

# Install prerequisites
echo "INFO: Installing prerequisites"
sudo add-apt-repository ppa:openjdk-r/ppa
sudo apt update
sudo apt install apt-transport-https curl gnupg-agent ca-certificates software-properties-common -y

# Install Docker
if [ -x "$(command -v docker)" ]; then
    echo "INFO: Docker client already installed"
    # command
else
    echo "INFO: Installing Docker client"
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
	sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
	sudo apt install docker-ce docker-ce-cli containerd.io -y
	sudo usermod -aG docker $USER
	newgrp docker
fi

# Starting Docker service
echo "Info: Starting and enabling Docker client"
sudo systemctl start docker
sudo systemctl enable docker
if [ -d "/home/$USER/minecraft-data" ] 
then
    echo "Directory /home/$USER/minecraft-data exists. This directory will be used to store the servers configuration files and data" 
else
    echo "WARN: Directory '/home/$USER/minecraft-data' does not exists."
    echo "INFO: Creating directory"
    mkdir /home/$USER/minecraft-data # Creating Docker volume directory to store MC server configuration files
fi

# Running Minecraft Server as a Docker container
echo "INFO: Checking Docker container status"
if [ ! "$(docker ps -q -f name=mc-server)" ]; then
    if [ "$(docker ps -aq -f status=exited -f name=mc-server)" ]; then
        # cleanup
        docker rm mc-server
        echo "INFO: Cleaned exited container"
    fi
    # run your container
    echo "INFO: Deploying Minecraft server Docker container"
    docker run -d -it -p 25565:25565 --name mc-server --restart unless-stopped -v /home/$USER/minecraft-data:/data itzg/minecraft-server
fi
echo "INFO: Minecraft server installation script finished"
```

# Server Usage
To learn more on modifying the server configurations using the /etc/mc-server/minecraft-data/server.properties file, read more here - https://minecraft.fandom.com/wiki/Server.properties#Minecraft_server_properties

To restart the mc-server, run the following command:
```bash
$ docker restart mc-server
```

For viewing server logs:
```bash
docker logs mc-server
```

To delete the mc-server Docker container:
```bash
docker rm -f mc-server
```

Restore server backup:
```bash
tar -tzvf /mnt/backup/host-Monday.tgz
tar -xzvf /mnt/backup/host-Monday.tgz -C /tmp etc/hosts
cd /
sudo tar -xzvf /mnt/backup/host-Monday.tgz
```
