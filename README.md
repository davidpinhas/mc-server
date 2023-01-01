![Minecraft Server](img/mc-server.png)

Install Minecraft server on ARM architecture using Oracle Cloud Infrastructure.

The server will be installed as a container using the Docker client and will retain the server's data in the directory '/etc/mc-server/minecraft-data', by default. 
To evert data loss when the server encounters applicative issues or data corruption, the 'mc-backup' script will run on a daily basis, using a CRON job backing up the server's data to the directory '/tmp/minecraft-backup' and will keep snapshots of data older less than 10 days.

# Server Usage
### Server maintainance
To restart the mc-server, run the following command:
```bash
sudo docker restart mc-server
```

For viewing server logs:
```bash
sudo docker logs mc-server
```

To delete the mc-server Docker container:
```bash
sudo docker rm -f mc-server
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
sudo docker logs -f mc-server
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
sudo bash mc-init.sh $NUMBER
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

To learn more about the server configurations, read more [here](https://minecraft.fandom.com/wiki/Server.properties#Minecraft_server_properties).
