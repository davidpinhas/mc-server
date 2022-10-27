#!/bin/bash

###################################
##### Minecraft Backup Script #####
###################################

# Location of Minecraft server data
backup_files="/home/$USER/minecraft-data"

# Where to backup to.
if [ -d "/home/$USER/minecraft-backup" ] 
then
    echo "Directory /home/$USER/minecraft-backup exists." 
else
    echo "WARN: Directory '/home/$USER/minecraft-backup' does not exists."
    echo "INFO: Creating directory"
    mkdir /home/$USER/minecraft-backup
fi
dest="/home/$USER/minecraft-backup"

# Create archive filename.
day=$(date +%A)
hostname=$(hostname -s)
archive_file="$hostname-$day.tgz"

# Print start status message.
echo "INFO: Backing up $backup_files to $dest/$archive_file"
date
echo

# Backup the files using tar.
tar czf $dest/$archive_file $backup_files

# Print end status message.
echo
echo "INFO: Backup finished"
date
