![Minecraft Server](img/mc-server.png)

Install Minecraft server on ARM architecture using Oracle Cloud Infrastructure.

The server will be installed as a container using the Docker client and will retain the server's data in the directory '/etc/mc-server/minecraft-data', by default. 
To evert data loss when the server encounters applicative issues or data corruption, the 'mc-backup' script will run on a daily basis, using a CRON job backing up the server's data to the directory '/tmp/minecraft-backup' and will keep snapshots of data older less than 10 days.

# Server Usage
### Server maintainance
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

### Server Backup/Restore
Backup  MC-Server:
```bash
mc-backup
```

Restore server backup:
```bash
mc-restore
```

After a successful restore it might take a few minutes to start the server up and we should see the following at the end of the startup process:
```bash
docker tail -f mc-server
```
```
[01:11:25] [Worker-Main-2/INFO]: Preparing spawn area: 96%
[01:11:25] [Worker-Main-1/INFO]: Preparing spawn area: 97%
[01:11:26] [Worker-Main-1/INFO]: Preparing spawn area: 98%
[01:11:26] [Worker-Main-2/INFO]: Preparing spawn area: 98%
[01:11:27] [Server thread/INFO]: Time elapsed: 101506 ms
[01:11:27] [Server thread/INFO]: Done (164.863s)! For help, type "help"
```

The retore command will take the latest MC-Server snapshot and restore it to the Minecraft /etc/mc-server/minecraft-data data directory.
The restoration process will stop the Docker container, delete the current data residing in /etc/mc-server/minecraft-data, and restore the latest snapshot located under the /home/$USER/minecraft-backup directory.

In case the restore process does not work as expected, consider performing a manual restore process.

# Server Configuration
### OCI VM Configuration
TODO

### Machine access
When creating a VM in OCI, we will have an option to generate a SSH keypair and using the private key for authentication.

To access the machine, SSH to the VM using the key for authentication:
```bash
ssh -i ~/.ssh/mc.key user@123.123.123.123
```

### Installation
To install mc-server, first clone this repo:
```bash
git clone https://github.com/davidpinhas/mc-server.git
cd mc-server
```

Than, run the installation script to start the MC-Server with specific memory size allocated to the service:
```bash
sudo bash mc-init.sh NUMBER
```

For example, we can pass '20' to allocate 20GB of memory for the service:
```bash
sudo bash mc-init.sh 20
```

In case a digit wasn't passed during the script startup, the MC-Server Docker container will start with the default value of 4GB memory limit.

### Post Installation
After successfully running the script, in order to modify the mc-server configuration file, run:
```bash
sudo vim /etc/mc-server/minecraft-data/server.properties 
```

To learn more about the server configurations, read more [here](https://minecraft.fandom.com/wiki/Server.properties#Minecraft_server_properties)

Full installation script:
```bash
#!/bin/bash

#########################################
##### Minecraft Installation Script #####
#########################################
# Verify root user
if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo "WARN: Not Sudo user. Please run as root, using the following command:"
    echo "$ sudo bash minecraft-server-install.sh"
    exit
fi

# Verify figlet
if [ ! -x "$(command -v figlet)" ]; then
    echo "INFO: Installing script prerequisites."
    sudo apt update > /dev/null 2>&1
    sudo apt install figlet -y > /dev/null 2>&1
fi

external_ip=$(dig -4 TXT +short o-o.myaddr.l.google.com @ns1.google.com)
figlet Minecraft Server Installer -f slant
memory_limit=$1
if [[ $1 -eq 0 ]]; then
    echo "WARN: No arguments provided.
INFO: Setting default memory limit to 4GB."
else
    if ! [[ $memory_limit =~ ^[0-9]{,2}$ && $memory_limit -ne 0 ]];then
    echo "ERROR: Not a number or a valid memory size.
Only numbers with up to two digit numbers are acceptable." >&2; exit 1
    else
        echo "INFO: Setting memory limit to ${memory_limit}GB."
    fi
fi

# Install prerequisites
echo "INFO: Installing prerequisites."
if [[ $(grep -rhE ^deb /etc/apt/sources.list* | grep openjdk-r) ]]; then
    echo "INFO: OpenJDK repository already exists."
else
    echo "INFO: Adding OpenJDK repository."
    sudo add-apt-repository ppa:openjdk-r/ppa -y > /dev/null 2>&1
fi
echo "INFO: Installing required packages."
sudo apt update > /dev/null 2>&1
if [[ $(dpkg -l | grep -i apt-transport-https | head -1) ]]; then
    echo "INFO: Package apt-transport-https installed."
else
    echo "INFO: Installing apt-transport-https."
    sudo apt install apt-transport-https -y > /dev/null 2>&1
fi
if [[ $(dpkg -l | grep -i vim | head -1) ]]; then
    echo "INFO: Package vim installed."
else
    echo "INFO: Installing vim."
    sudo apt install vim -y > /dev/null 2>&1
fi
if [[ $(dpkg -l | grep -i curl | head -1) ]]; then
    echo "INFO: Package curl installed."
else
    echo "INFO: Installing curl."
    sudo apt install curl -y > /dev/null 2>&1
fi
if [[ $(dpkg -l | grep -i gnupg-agent | head -1) ]]; then
    echo "INFO: Package gnupg-agent installed."
else
    echo "INFO: Installing gnupg-agent."
    sudo apt install gnupg-agent -y > /dev/null 2>&1
fi
if [[ $(dpkg -l | grep -i ca-certificates | head -1) ]]; then
    echo "INFO: Package ca-certificates installed."
else
    echo "INFO: Installing ca-certificates."
    sudo apt install ca-certificates -y > /dev/null 2>&1
fi
if [[ $(dpkg -l | grep -i software-properties-common | head -1) ]]; then
    echo "INFO: Package software-properties-common installed."
else
    echo "INFO: Installing software-properties-common."
    sudo apt install software-properties-common -y > /dev/null 2>&1
fi

# Install Docker
if [ -x "$(command -v docker)" ]; then
    echo "INFO: Docker client already installed. Proceeding."
else
    echo "INFO: Checking Docker repository."
    if [[ $(grep -rhE ^deb /etc/apt/sources.list* | grep "https://download.docker.com/linux/ubuntu") ]]; then
        echo "INFO: Docker repository already exists."
    else
        echo "INFO: Adding Docker repository."
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - 
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable" -y > /dev/null 2>&1
    fi
    echo "INFO: Installing Docker client."
    if [[ $(dpkg -l | grep -i docker-ce | head -1) ]]; then
        echo "INFO: docker-ce installed."
    else
        echo "INFO: Installing docker-ce."
        sudo apt install docker-ce -y > /dev/null 2>&1
    fi
    if [[ $(dpkg -l | grep -i docker-ce-cli | head -1) ]]; then
        echo "INFO: docker-ce-cli installed."
    else
        echo "INFO: Installing docker-ce-cli."
        sudo apt install docker-ce-cli -y > /dev/null 2>&1
    fi
    if [[ $(dpkg -l | grep -i containerd.io | head -1) ]]; then
        echo "INFO: containerd.io installed."
    else
        echo "INFO: Installing containerd.io."
        sudo apt install containerd.io -y > /dev/null 2>&1
    fi
    echo "INFO: Setting Docker user."
	sudo usermod -aG docker $USER
    if [[ $(groups | grep docker) ]]; then
        echo "INFO: Docker group already exists."
    else
        echo "INFO: Creating Docker group."
        sudo newgrp docker
    fi
fi

# Starting Docker service
echo "INFO: Starting and enabling the Docker client."
if [[ ! $(sudo systemctl status docker | grep "Active: active (running)") ]]; then
  echo "WARN: Docker client is not working properly."
  echo "INFO: Trying to restart the service."
  sudo systemctl restart docker > /dev/null 2>&1
fi
sleep 10
if [[ ! $(sudo systemctl status docker | grep "Active: active (running)") ]]; then
echo "WARN: Docker client still isn't working properly."
echo "INFO: Do you wish to reinstall the Docker client?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) echo "INFO: Purging Docker client."
        sudo apt-get remove --purge docker-ce docker-ce-cli containerd.io -y > /dev/null 2>&1
        echo "INFO: Reinstalling Docker client."
        sudo apt-get install docker-ce docker-ce-cli containerd.io -y > /dev/null 2>&1
        echo "INFO: Starting Docker client service."
        sudo systemctl start docker > /dev/null 2>&1
        break
        ;;
        No ) echo "Minecraft server installation script exited."
        exit
        ;;
    esac
done
fi
sleep 10
if [[ ! $(sudo systemctl status docker | grep "Active: active (running)") ]]; then
    echo "ERROR: Unstable Docker client! Exiting script."
    echo "ERROR: Re-running the script may resolve the issue in some cases.

If the issue persists, resolve the Docker client issue and re-run the script."
    exit
fi
service docker status &> /dev/null || service docker start
sudo systemctl enable docker > /dev/null 2>&1
if [ -d "/etc/mc-server/minecraft-data" ] 
then
    echo "INFO: Directory /etc/mc-server/minecraft-data exists." 
else
    echo "WARN: Directory '/etc/mc-server/minecraft-data' does not exists."
    echo "INFO: Creating directory /etc/mc-server/minecraft-data."
    sudo mkdir -p /etc/mc-server/minecraft-data # Creating Docker volume directory to store MC server configuration files
fi

# Setting up server backup command and job
echo "INFO: Copying mc-backup script to bin directory."
sudo cp mc-backup.sh /usr/bin/mc-backup
sudo chmod +x /usr/bin/mc-backup
echo "INFO: Setting backup script with cron."
#write out current crontab
crontab -l > mc-cron
#echo new cron into cron file
echo "0 0 * * * mc-backup" >> mc-cron
#install new cron file
crontab mc-cron
echo "INFO: Successfully setup cron job to automate backups."
echo "INFO: Removing temp cron file."
rm mc-cron

# Setting up server restore command
echo "INFO: Copying mc-restore script to bin directory."
sudo cp mc-restore.sh /usr/bin/mc-restore
sudo chmod +x /usr/bin/mc-restore

# Running Minecraft Server as a Docker container
echo "INFO: Checking Docker container status."
if [ "$(docker ps -f name=mc-server)" ]; then
    echo "WARN: MC-Server container exists, deleting container."
    sudo docker rm -f mc-server > /dev/null 2>&1
    echo "WARN: Found data in /etc/mc-server/minecraft-data."
    if [ -d "/tmp/minecraft-backup" ]; then
        echo "INFO: Directory /tmp/minecraft-backup exists." 
    else
        echo "WARN: Directory '/tmp/minecraft-backup' does not exists."
        echo "INFO: Creating directory /tmp/minecraft-backup."
        sudo mkdir -p /tmp/minecraft-backup # Creating Docker volume directory to store MC server configuration files
    fi
    echo "INFO: Backing up tarball to /tmp/minecraft-backup/mc-script-bkp.tgz."
    sudo tar czf /tmp/minecraft-backup/mc-script-bkp.tgz /etc/mc-server/minecraft-data > /dev/null 2>&1
    echo "INFO: Cleaning mc-server data directory."
    sudo rm -rf /etc/mc-server/minecraft-data/*
fi
if [ $# -ge 1 ]; then
    memory_count+="${memory_limit}000m"
    echo "INFO: Deploying Minecraft server Docker container with ${memory_count} memory limit."
    sudo docker run -d -it -p 25565:25565 --name mc-server -e EULA=TRUE -e MEMORY="" -e JVM_XX_OPTS="-XX:MaxRAMPercentage=100" -m $memory_count --restart unless-stopped -v /etc/mc-server/minecraft-data:/data itzg/minecraft-server > /dev/null 2>&1
else
    echo "WARN: Didn't provide memory limit on script startup. Running with default."
    memory_count="4000m"
    sudo docker run -d -it -p 25565:25565 --name mc-server -e EULA=TRUE -e MEMORY="" -e JVM_XX_OPTS="-XX:MaxRAMPercentage=100" -m $memory_count --restart unless-stopped -v /etc/mc-server/minecraft-data:/data itzg/minecraft-server > /dev/null 2>&1
fi
echo "INFO: Waiting for mc-server data files to copy from the Docker container."
while [ $(ls -l /etc/mc-server/minecraft-data | wc -l) != 13 ]
do
    echo "INFO:" $(ls -l /etc/mc-server/minecraft-data | wc -l) "out of 13 files copied. Waiting 10 seconds."
    sleep 10
done
echo "INFO: Successfully copied data files to /etc/mc-server/minecraft-data directory."
echo "INFO: Waiting for mc-server container to start.
Take a coffee/tea break, this might take a few minutes.
"
container_status=$(sudo docker inspect -f {{.State.Health.Status}} mc-server)
while [ "$(sudo docker inspect -f {{.State.Health.Status}} mc-server | grep -wh "healthy")" != "healthy" ]; do
  echo "INFO: Startup in progress. Current state is '$container_status'."
  sleep 20
done
echo "INFO: Docker container is running."

# Script output
echo "INFO: Minecraft server installation script finished."
echo "
#################################
##### MINECRAFT SERVER INFO #####
#################################

## Minecraft Properties:"
cat /etc/mc-server/minecraft-data/server.properties | grep "gamemode"
cat /etc/mc-server/minecraft-data/server.properties | grep "pvp"
cat /etc/mc-server/minecraft-data/server.properties | grep "difficulty"
cat /etc/mc-server/minecraft-data/server.properties | grep "max-players"
cat /etc/mc-server/minecraft-data/server.properties | grep "max-world-size"
echo "Container Memory limit=${memory_count}"
echo "
To modify these settngs, read more here:
https://minecraft.fandom.com/wiki/Server.properties#Minecraft_server_properties

## Minecraft server endpoint:"
echo "$(echo $external_ip | tr -d '"'):25565"

echo "
## Minecraft server data location:
/etc/mc-server/minecraft-data

This directory will be used to store the servers configuration files and data.
The backup script will run everyday at 12AM.

To run the backup script:
mc-backup

To restore the mc-server with the latest backup snapshot:
mc-restore

For more details, visit https://github.com/davidpinhas/mc-server."
```