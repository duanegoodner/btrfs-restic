#!/bin/bash


SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DOT_ENV_FILE="$SCRIPT_DIR/../.env"
# shellcheck disable=SC1090
source "$DOT_ENV_FILE"
SERVER_SCRIPT_LOCAL_PATH="$SCRIPT_DIR/server_init.sh"

# Initialize an empty array for SUBVOL_LIST
SUBVOL_LIST=()

# Iterate over BTRFS_SUBVOLUMES and extract the subvolume names
for entry in "${BTRFS_SUBVOLUMES[@]}"; do
  # Extract the part after the '=' character and add it to SUBVOL_LIST
  subvol="${entry#*=}"
  SUBVOL_LIST+=("$subvol")
done

# Convert SUBVOL_LIST to a space-separated string
SUBVOL_LIST_STR="${SUBVOL_LIST[*]}"


# shellcheck disable=SC2087
ssh -i "$SSH_KEYFILE" "$RESTIC_SERVER_USER@$RESTIC_SERVER" 'sudo -S bash -s' << EOF
$(zenity --password)
export RESTIC_REPOS_DIR="$RESTIC_REPOS_DIR"
export SUBVOL_LIST_STR="$SUBVOL_LIST_STR"
export RESTIC_SERVER_USER="$RESTIC_SERVER_USER"
$(cat "$SERVER_SCRIPT_LOCAL_PATH")
EOF

echo "${SUBVOL_LIST[@]}"

for repo_name in "${SUBVOL_LIST[@]}"; do
  cur_repo=sftp:"$RESTIC_SERVER_USER"@"$RESTIC_SERVER":"$RESTIC_REPOS_DIR"/"$repo_name"
  "$RESTIC_BINARY" -r "$cur_repo" init --password-file "$RESTIC_REPOS_PASSWORD_FILE"
done




