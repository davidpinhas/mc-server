####################################
##### Minecraft Restore Script #####
####################################

# Location of Minecraft server data
backup_files="/home/$USER/minecraft-backup"

# Where to backup to.
if [ ! -d "/home/$USER/minecraft-backup" ] 
then
    echo "ERROR: Directory '/home/$USER/minecraft-backup' does not exists."
    exit
fi
dest="/etc/mc-server/minecraft-data"
latest_backup=$(ls -Art /home/$USER/minecraft-backup | tail -n 1)

# Print start status message.
echo "INFO: Restoring $backup_files/$latest_backup to $dest."
date
echo

echo "INFO: Stoping mc-server Docker container."
sudo docker stop mc-server
while [ "$(sudo docker ps -a | grep mc-server | awk '{print $7}')" != "Exited" ]; do
  echo "INFO: Container state is '${sudo docker ps -a | grep mc-server | awk '{print $7}'}'. Waiting for shutdown."
  sleep 2
done
echo "INFO: Docker container was stopped."

# Restore the files using tar.
echo "INFO: Deleting data from mc-server data from /etc/mc-server/minecraft-data directory."
sudo rm -rf $dest/*
mkdir mc-tmp
echo "INFO: Extracting the latest $latest_backup backup snapshot."
sudo tar -zvxf $backup_files/$latest_backup -C mc-tmp
sudo cp -r mc-tmp$dest/* $dest/.
echo "INFO: Starting mc-server Docker container."
sudo docker start mc-server
sudo rm mc-tmp
startup_status=$(sudo docker inspect -f {{.State.Health.Status}} mc-server)
while [ "$(sudo docker inspect -f {{.State.Health.Status}} mc-server | grep -wh "healthy")" != "healthy" ]; do
  echo "INFO: Startup in progress. Current state is '$startup_status'."
  sleep 5
done
echo "INFO: Docker container is running."

# Print end status message.
echo
echo "INFO: Restore finished."
date
