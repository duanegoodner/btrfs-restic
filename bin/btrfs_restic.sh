#!/bin/bash

# shellcheck source=../btrfs_restic.env
DOT_ENV_FILE=../btrfs_restic.env

load_dot_env() {

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
  current_time=$(date +"%Y_%m_%d_%H_%M_%S_%N")

  # Define the filename with the current time
  filename="restic-${current_time}.log"

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
  if sudo /usr/bin/btrfs subvolume snapshot "$source_mount" "$destination"; then
  # if [ $? -eq 0 ]; then
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

run_backup () {
  if [[ "$TIMESTAMP_LOG" == true ]]; then
  backup 2>&1 | tee >(ts '[%Y-%m-%d %H:%M:%.S]' >> "$BTRFS_RESTIC_LOG_FILE")
else
  backup 2>&1
fi
}

load_dot_env
check_preconditions
create_log_file
run_backup