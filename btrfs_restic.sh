#!/bin/bash

# btrfs_restic_backup.sh
#
# Description:
#   This script takes snapshots of specified Btrfs subvolumes and sends these snapshots to a Restic repository.
#   Before running, CONFIG_DIR must be set to a valid directory path, and this directory must contain a
#   btrfs_restic.env file. See README.md for detailed instructions.


# ###### Must assign value to CONFIG_DIR. This is parent dir of .env file #####
DOT_ENV_FILE=btrfs_restic.env

load_dot_env() {
  # Load environment variables from .env file
  if [ -f "$DOT_ENV_FILE" ]; then
    source "$DOT_ENV_FILE"
  else
    echo ".env file not found." >&2
    exit 1
  fi
}

check_preconditions() {
  if [ ! -e "$DOT_ENV_FILE" ]; then
    echo ".env file not found." >&2
    exit 1
  fi

  # confirm ssh key is present
  if [ ! -e "$SSH_KEYFILE" ]; then
    echo "key file not found." >&2
    exit 1
  fi

  # confirm BTRFS_SNAPSHOTS_DIR exists
  if [ ! -e "$BTRFS_SNAPSHOTS_DIR" ]; then
    echo "$BTRFS_SNAPSHOTS_DIR (BTRFS_SNAPSHOTS_DIR in .env) not found." >&2
    exit 1
  fi

}

create_log_file() {
  # Get the current date and time in the desired format
  current_time=$(date +"%Y_%m_%d_%H_%M_%S")

  # Define the filename with the current time
  filename="${current_time}.log"

  mkdir -p "$LOG_DIR"
  touch "$LOG_DIR"/"$filename"

  export BTRFS_RESTIC_LOG_FILE="$LOG_DIR"/"$filename"
}

# Function to create a snapshot
create_snapshot() {
  local source_mount=$1
  local snapshot_name=$2
  local destination="${BTRFS_SNAPSHOTS_DIR}/${snapshot_name}"

  # Create the snapshot
  sudo /usr/bin/btrfs subvolume snapshot "$source_mount" "$destination"
  if [ $? -eq 0 ]; then
    echo "Snapshot of $source_mount created at $destination"
  else
    echo "Failed to create snapshot of $source_mount"
  fi
}

backup() {

  export RESTIC_PASSWORD_FILE="$RESTIC_REPOS_PASSWORD_FILE"

  # Loop through the mount points and create snapshots
  for entry in "${BTRFS_SUBVOLUMES[@]}"; do
    IFS='=' read -r mount_point snapshot_name <<<"$entry"

    echo "Creating local btrfs snapshot"
    cur_repo=sftp:"$RESTIC_SERVER_USER"@"$RESTIC_SERVER":"$RESTIC_REPOS_DIR"/"$snapshot_name"
    create_snapshot "$mount_point" "$snapshot_name"

    echo "Sending incrementsl back up of ${BTRFS_SNAPSHOTS_DIR}/${snapshot_name} to ${cur_repo}"
    "$HOME"/bin/restic_fullread -r "${cur_repo}" --verbose backup "${BTRFS_SNAPSHOTS_DIR}/${snapshot_name}"
    sudo /usr/bin/btrfs subvolume delete "${BTRFS_SNAPSHOTS_DIR}/${snapshot_name}"
  done

  unset "$RESTIC_RESTIC_REPOS_PASSWORD_FILE"

}

load_dot_env
check_preconditions
create_log_file
backup 2>&1 | ts '[%Y-%m-%d %H:%M:%.S]' | tee -a "$BTRFS_RESTIC_LOG_FILE"
