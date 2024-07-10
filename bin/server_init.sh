#!/bin/bash


SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DOT_ENV_FILE="$SCRIPT_DIR/../.env"
# shellcheck disable=SC1090
source "$DOT_ENV_FILE"
UTILS_SCRIPT_LOCAL_PATH="$SCRIPT_DIR/utils.sh"
# shellcheck disable=SC1090
source "$UTILS_SCRIPT_LOCAL_PATH"

SERVER_SCRIPT_LOCAL_PATH="$SCRIPT_DIR/create_repo_dirs.sh"

# store the "values" from MOUNT_POINT_REPO_LIST as serialized string
SUBVOL_LIST_SERIALIZED=$(get_vals "${MOUNTPOINT_REPO_LIST[@]}")
deserialize_array "$SUBVOL_LIST_SERIALIZED" SUBVOL_LIST

# shellcheck disable=SC2087
ssh -i "$SSH_KEYFILE" "$RESTIC_SERVER_USER@$RESTIC_SERVER" 'sudo -S bash -s' << EOF
$(zenity --password --title="sudo on $RESTIC_SERVER" --text="Enter sudo password")
export RESTIC_REPOS_DIR="$RESTIC_REPOS_DIR"
export SUBVOL_LIST_SERIALIZED="$SUBVOL_LIST_SERIALIZED"
export RESTIC_SERVER_USER="$RESTIC_SERVER_USER"
$(cat "$UTILS_SCRIPT_LOCAL_PATH")
$(cat "$SERVER_SCRIPT_LOCAL_PATH")
EOF


# declare SUBVOL_LIST
# deserialize_list SUBVOL_LIST_STR SUBVOL_LIST
# IFS=' ' read -r -a SUBVOL_LIST <<< "$SUBVOL_LIST_STR"

for repo_name in "${SUBVOL_LIST[@]}"; do
  cur_repo=sftp:"$RESTIC_SERVER_USER"@"$RESTIC_SERVER":"$RESTIC_REPOS_DIR"/"$repo_name"
  "$RESTIC_BINARY" -r "$cur_repo" init --password-file "$RESTIC_REPOS_PASSWORD_FILE"
done




