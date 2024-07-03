#!/bin/bash

# BACKUP_USER=duane
# BACKUP_CONFIG_DIR=/home/"$BACKUP_USER"/.restic
# LOG_DIR="$BACKUP_CONFIG_DIR"/logs
# DOT_ENV_FILE="$BACKUP_CONFIG_DIR"/.env

BACKUP_USER=duane
BACKUP_CONFIG_DIR=/home/duane/dproj/btrfs_restic/config_dir
LOG_DIR="$BACKUP_CONFIG_DIR"/logs
DOT_ENV_FILE="$BACKUP_CONFIG_DIR"/.env

load_dot_env() {
    # Load environment variables from .env file
    if [ -f "$DOT_ENV_FILE" ]; then
        source "$DOT_ENV_FILE"
    else
        echo ".env file not found." >&2
        exit 1
    fi
}

load_dot_env

ssh restic@192.168.50.210 <<"EOF"
$(for entry in "${BTRFS_MOUNT_POINTS[@]}"; do
echo "pwd"
done)
EOF

# Loop through the mount points and create snapshots
# for entry in "${BTRFS_MOUNT_POINTS[@]}"; do
#     IFS='=' read -r mount_point snapshot_name <<<"$entry"
#     echo $mount_point $snapshot_name

    # echo "Checking for repo"
    # repo_path="$RESTIC_ROOT/$snapshot_name"
    # ssh "$RESTIC_USER@$RESTIC_SERVER"

    # cur_repo="$RESTIC_CONNECTION":"$RESTIC_ROOT"/"$snapshot_name"
    # echo "$cur_repo"
    # restic -r "$cur_repo" ls latest

    # echo "Sending incrementsl back up of ${SNAPSHOT_BASE_DIR}/${snapshot_name} to ${RESTIC_REPO}"
    # ~/bin/restic_fullread -r "${RESTIC_REPO}" --verbose backup "${SNAPSHOT_BASE_DIR}/${snapshot_name}"
    # sudo /usr/bin/btrfs subvolume delete "${SNAPSHOT_BASE_DIR}/${snapshot_name}"
# done

# exit
