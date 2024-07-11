#!/bin/bash

# Creates directories and initializes Restic repositories on remote server

# identify directory of this file
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
lib_dir="$script_dir/../lib"

# build path to .env and import
source "$script_dir/../etc/.env"

# build path to utils.sh and import
utils_script="$lib_dir/utils.sh"
# shellcheck disable=SC1090
source "$utils_script"

# build path to create_repo_dirs.sh (will need to run via ssh on server) 
repo_dir_creation_script="$lib_dir/create_repo_dirs.sh"

# store the "values" from MOUNT_POINT_REPO_LIST as serialized string, then deserialize into array
subvol_list_serialized=$(get_vals "${MOUNTPOINT_REPO_LIST[@]}")
declare -a subvol_list
deserialize_array "$subvol_list_serialized" subvol_list


# ssh into server and run create_repo_dirs.sh to create directories that will be used as restic repos
ssh_commands=$(cat <<EOF
$(zenity --password --title="sudo on $RESTIC_SERVER" --text="Enter sudo password")
export RESTIC_REPOS_DIR="$RESTIC_REPOS_DIR"
export SUBVOL_LIST_SERIALIZED="$subvol_list_serialized"
export RESTIC_SERVER_USER="$RESTIC_SERVER_USER"
$(cat "$utils_script")
$(cat "$repo_dir_creation_script")
EOF
)
# shellcheck disable=SC2087
ssh -i "$SSH_KEYFILE" "$RESTIC_SERVER_USER@$RESTIC_SERVER" 'sudo -S bash -s' <<< "$ssh_commands"

# initializes a restic repository
initialize_repo() {
  local repo_name=$1
  cur_repo=sftp:"$RESTIC_SERVER_USER"@"$RESTIC_SERVER":"$RESTIC_REPOS_DIR"/"$repo_name"
  "$RESTIC_BINARY" -r "$cur_repo" init --password-file "$RESTIC_REPOS_PASSWORD_FILE"
}

# Initialize restic repos. Calls are made on local machine, using sftp paths to repos 
for repo_name in "${subvol_list[@]}"; do
  initialize_repo "$repo_name"
done




