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
dest="/home/$USER/minecraft-data"
latest_backup=$(ls -Art /home/$USER/minecraft-backup | tail -n 1)

# Print start status message.
echo "INFO: Restoring $backup_files/$latest_backup to $dest"
date
echo

echo "INFO: Stoping mc-server Docker container"
sudo docker stop mc-server
# Restore the files using tar.
echo "INFO: Deleting data from mc-server data from /home/$USER/minecraft-data directory."
rm -rf $dest/*
echo "INFO: Extracting the latest $latest_backup backup snapshot"
tar -zvxf $backup_files/$latest_backup $dest
echo "INFO: Starting mc-server Docker container"
sudo docker start mc-server

# Print end status message.
echo
echo "INFO: Restore finished"
date
