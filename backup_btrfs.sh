#!/bin/bash

# Configuration for restic repository


RESTIC_REPOSITORY="sftp:duane@192.168.50.210:/srv/client_backups/debian-butest-1/root"
subvol_paths=

# Function to handle snapshots and backup
backup_subvolume() {
    local subvol_path=$1
    local subvol_name=$2
    local snapshot_path="/.snapshots_tmp/${subvol_name}"

    sudo rm -rf $snapshot_path
    
    echo "Creating snapshot of ${subvol_name}"
    sudo btrfs subvolume snapshot "${subvol_path}" "${snapshot_path}"

    echo "Backing up the snapshot"
    sudo restic -r $RESTIC_REPOSITORY backup "${snapshot_path}"

    echo "Removing the snapshot"
    sudo rm -rf $snapshot_path
}

# Backup root subvolume
backup_subvolume "/" "root"

# Backup home subvolume
backup_subvolume "/home" "home"
