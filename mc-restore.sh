###################################
##### Minecraft Restore Script #####
###################################

# Location of Minecraft server data
backup_files="/home/$USER/minecraft-backup"

# Where to backup to.
if [ -d "/home/$USER/minecraft-backup" ] 
    echo "ERROR: Directory '/home/$USER/minecraft-backup' does not exists."
    exit
fi
dest="/home/$USER/minecraft-data"
latest_backup=$(ls -Art /home/$USER/minecraft-backup | tail -n 1)

# Print start status message.
echo "INFO: Restoring $backup_files/$latest_backup to $dest"
date
echo

# Restore the files using tar.
tar -zvxf $backup_files/$latest_backup $dest/.

# Print end status message.
echo
echo "INFO: Restore finished"
date
