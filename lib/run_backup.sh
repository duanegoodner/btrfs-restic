#!/bin/bash

# btrfs_restic_backup.sh
#
# Description:
# Takes snapshots of BTRFS subvolumes and sends thethe snapshot content to a Restic repository.
# See README.md for details.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR"/../lib
DOT_ENV_FILE="$SCRIPT_DIR/../etc/btrfs_restic.env"
UTILS_FILE="$LIB_DIR/utils.sh"


# checks that required files and directory are present
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

# loads env file
load_dot_env() {
  if [ -f "$DOT_ENV_FILE" ]; then
    # shellcheck disable=SC1090
    source "$DOT_ENV_FILE"
  else
    echo ".env file not found." >&2
    exit 1
  fi
}

load_utils() {
    if [ -f "$UTILS_FILE" ]; then
    # shellcheck disable=SC1090
    source "$UTILS_FILE"
  else
    echo "utils.sh file not found." >&2
    exit 1
  fi
}

get_args() {
  # Default values
  custom_paths=""
  tag=""

  # Parse command line arguments
  while [[ "$#" -gt 0 ]]; do
    case $1 in
      --paths)
        if [[ -z $2 || $2 == --* ]]; then
            echo "Error: --paths requires a value"
            exit 1
        fi
        custom_paths="$2"
        shift 2
        ;;
      --tag)
        if [[ -z $2 || $2 == --* ]]; then
            echo "Error: --tag requires a value"
            exit 1
        fi
        tag="$2"
        shift 2
        ;;
      *)
        echo "Unknown parameter passed: $1"
        exit 1
        ;;
    esac
  done
}

get_backup_map() {

  # serialize array of key=mount_point:val=repo pairs defined in env file
  local serialized_mountpoint_repo_map
  serialized_mountpoint_repo_map=$(serialize_array MOUNTPOINT_REPO_LIST[@])

  # convert serialized array of key:val pairs to associative array
  local -A mountpoint_repo_map
  deserialize_map "$serialized_mountpoint_repo_map" mountpoint_repo_map

  local -A backup_map

  # if we have custom_paths, only take key:val pairs with key in custom_paths
  if [ -n "$custom_paths" ]; then
    local -a custom_paths_array
    deserialize_array "$custom_paths" custom_paths_array
    for entry in "${custom_paths_array[@]}"; do
      # shellcheck disable=SC2034
      backup_map["$entry"]="${mountpoint_repo_map["$entry"]}"
    done

    serialize_map backup_map

  else
    # if no custom paths, we can just output serialized array of key:val pairs generated earlier
    # b/c this is same form of serialized map with all key:val pairs
    echo "$serialized_mountpoint_repo_map"
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

# Creates a BTRFS snapshot=
create_btrfs_snapshot() {
  local mount_point=$1
  local snapshot_name=$2
  local destination="${BTRFS_SNAPSHOTS_DIR}/${snapshot_name}"

  # Create the snapshot
  if sudo /usr/bin/btrfs subvolume snapshot "$mount_point" "$destination"; then
    # if [ $? -eq 0 ]; then
    echo "Snapshot of $mount_point created at $destination"
  else
    echo "Failed to create snapshot of $mount_point"
  fi
}

send_btrfs_snapshot_to_restic() {
  local repo_name=$1

  local cur_repo=sftp:"$RESTIC_SERVER_USER"@"$RESTIC_SERVER":"$RESTIC_REPOS_DIR"/"$repo_name"
  echo "Sending incremental back up of ${BTRFS_SNAPSHOTS_DIR}/${repo_name} to ${cur_repo}"
  export RESTIC_PASSWORD_FILE="$RESTIC_REPOS_PASSWORD_FILE"
  if [ -n "$tag" ]; then
    "$RESTIC_BINARY" -r "${cur_repo}" --verbose backup "${BTRFS_SNAPSHOTS_DIR}/${repo_name}" --tag "$tag"
  else
    "$RESTIC_BINARY" -r "${cur_repo}" --verbose backup "${BTRFS_SNAPSHOTS_DIR}/${repo_name}"
  fi
  unset "$RESTIC_REPOS_PASSWORD_FILE"
  # sudo /usr/bin/btrfs subvolume delete "${BTRFS_SNAPSHOTS_DIR}/${repo_name}"
}

delete_btrfs_snapshot() {
  local repo_name=$1
  sudo /usr/bin/btrfs subvolume delete "${BTRFS_SNAPSHOTS_DIR}/${repo_name}"
}

backup_subvol_to_repo() {
  local mount_point=$1
  local repo_name=$2

  echo "Creating local btrfs snapshot"
  create_btrfs_snapshot "$mount_point" "$repo_name"
  send_btrfs_snapshot_to_restic "$repo_name"
  delete_btrfs_snapshot "$repo_name"

}

# Takes snapshots and sends to Restic repo
backup() {

  local serialized_backup_map=$1
  local -A backup_map
  deserialize_map "$serialized_backup_map" backup_map
  for key in "${!backup_map[@]}"; do
    # IFS=':' read -r mount_point repo_name <<<"$entry"
    echo "path=$key"
    echo "repo_name=${backup_map["$key"]}"
    backup_subvol_to_repo "$key" "${backup_map["$key"]}"
  done
}

# Calls backup() with logging mode specified in env file
run_backup() {
  local serialized_backup_map=$1
  if [[ "$TIMESTAMP_LOG" == true ]]; then
    backup "$serialized_backup_map" 2>&1 | tee >(ts '[%Y-%m-%d %H:%M:%.S]' >>"$BTRFS_RESTIC_LOG_FILE")
  else
    backup "$serialized_backup_map" 2>&1
  fi
}

load_dot_env
load_utils
check_preconditions
get_args "$@"
echo "tag=$tag"
declare serialized_backup_map
serialized_backup_map=$(get_backup_map)
echo "$serialized_backup_map"
create_log_file
run_backup "$serialized_backup_map"
