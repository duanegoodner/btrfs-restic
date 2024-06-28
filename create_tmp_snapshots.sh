#!/bin/bash

# Load environment variables from .env file
if [ -f .env ]; then
  source .env
else
  echo ".env file not found!"
  exit 1
fi

# Function to create a snapshot
create_snapshot() {
  local source_mount=$1
  local snapshot_name=$2
  local destination="${SNAPSHOT_BASE}/${snapshot_name}"

  # Create the snapshot
  sudo /usr/bin/btrfs subvolume snapshot "$source_mount" "$destination"
  if [ $? -eq 0 ]; then
    echo "Snapshot of $source_mount created at $destination"
  else
    echo "Failed to create snapshot of $source_mount"
  fi
}

# Define the snapshot base directory
SNAPSHOT_BASE="/.snapshots_tmp"

# Ensure the snapshot base directory exists
mkdir -p "$SNAPSHOT_BASE"

# Loop through the mount points and create snapshots
for entry in "${BTRFS_MOUNT_POINTS[@]}"; do
  echo "$entry"
  # IFS='=' read -r mount_point snapshot_name <<< "$entry"
  # create_snapshot "$mount_point" "$snapshot_name"
  # sudo ~/bin/restic -r "${RESTIC_REPO}" backup "${SNAPSHOT_BASE}/${snapshot_name}"
done


