#!/bin/bash

BACKUP_USER=duane
BACKUP_CONFIG_DIR=/home/"$BACKUP_USER"/.backup_config
export RESTIC_PASSWORD_FILE="$BACKUP_CONFIG_DIR"/repo_password
DOT_ENV_FILE="$BACKUP_CONFIG_DIR"/.env


# Load environment variables from .env file
if [ -f "$DOT_ENV_FILE" ]; then
  source "$DOT_ENV_FILE"
else
  echo ".env file not found!"
  exit 1
fi

# confirm ssh key is present
if [ ! -e  "$KEYFILE" ]; then
  echo "key file not found!"
  exit 1
fi

# Function to create a snapshot
create_snapshot() {
  local source_mount=$1
  local snapshot_name=$2
  local destination="${SNAPSHOT_BASE_DIR}/${snapshot_name}"

  # Create the snapshot
  sudo /usr/bin/btrfs subvolume snapshot "$source_mount" "$destination"
  if [ $? -eq 0 ]; then
    echo "Snapshot of $source_mount created at $destination"
  else
    echo "Failed to create snapshot of $source_mount"
  fi
}


# Ensure the snapshot base directory exists
sudo mkdir -p "$SNAPSHOT_BASE_DIR"


# Loop through the mount points and create snapshots
for entry in "${BTRFS_MOUNT_POINTS[@]}"; do
  IFS='=' read -r mount_point snapshot_name <<< "$entry"
  create_snapshot "$mount_point" "$snapshot_name"
  ~/bin/restic_fullread -r "${RESTIC_REPO}" backup "${SNAPSHOT_BASE_DIR}/${snapshot_name}"
  sudo /usr/bin/btrfs subvolume delete "${SNAPSHOT_BASE_DIR}/${snapshot_name}"
done

unset "$RESTIC_PASSWORD_FILE"


