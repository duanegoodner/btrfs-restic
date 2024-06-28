#!/bin/bash





create_snapshot() {
    local source_mount_point=$1
    local snapshot_name=$2
    local snapshot_base=${3:-$SNAPSHOT_BASE_DIR}
    local destination="${snapshot_base}/${snapshot_name}"

    # Create the snapshot
    sudo /usr/bin/btrfs subvolume snapshot "$source_mount_point" "$destination"
    if [ $? -eq 0 ]; then
        echo "Snapshot of $source_mount_point created at $destination"
    else
        echo "Failed to create snapshot of $source_mount_point"
    fi

    # send snapshot files to restic
    ~/bin/restic -r "${RESTIC_REPO}" backup "$destination"

    # remove local btrfs snapshot
    sudo rm -rf "$destination"


}

# Load environment variables from .env file
if [ -f .env ]; then
  source .env
else
  echo ".env file not found!"
  exit 1
fi

# Loop through the mount points and create snapshots
for entry in "${BTRFS_MOUNT_POINTS[@]}"; do
  echo "$entry"
  IFS='=' read -r mount_point snapshot_name <<< "$entry"
  create_snapshot "$mount_point" "$snapshot_name"
  # sudo ~/bin/restic -r "${RESTIC_REPO}" backup "${SNAPSHOT_BASE}/${snapshot_name}"
done




# Load environment variables from .env file
# if [ -f .env ]; then
#   source .env
# else
#   echo ".env file not found!"
#   exit 1
# fi

# create_snapshot /var/tmp var_tmp_new
