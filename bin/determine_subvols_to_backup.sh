#!/bin/bash


script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
dot_env_file="$script_dir/../.env"

# build path to utils.sh and import
utils_script="$script_dir/utils.sh"
# shellcheck disable=SC1090
source "$utils_script"

# loads env file
load_dot_env() {
  if [ -f "$dot_env_file" ]; then
    # shellcheck disable=SC1090
    source "$dot_env_file"
  else
    echo ".env file not found." >&2
    exit 1
  fi
}

get_args() {
       # Default value for custom_paths
    custom_paths=""

    # Parse command line arguments
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --paths=*) custom_paths="${1#*=}";;
            *) echo "Unknown parameter passed: $1"; exit 1;;
        esac
        shift
    done 
}

serialized_map_from_pairs_array MOUNTPOINT_REPO_LIST[@] "SERIALIZED_MOUNTPOINT_REPO_MAP"
declare -A deserialized_mountpoint_repo_map
deserialize_map "$SERIALIZED_MOUNTPOINT_REPO_MAP" deserialized_mountpoint_repo_map
echo "$SERIALIZED_MOUNTPOINT_REPO_MAP"


load_dot_env "$dot_env_file"

# # Call the argument_collector function
get_args "$@"

# # Output the value of custom_paths (for debugging purposes)

if [ -n "$custom_paths" ]; then
    echo "Performing backup for the following paths: $custom_paths"
    # Your backup logic using $custom_paths
    declare -a custom_paths_array
    deserialize_array "$custom_paths" custom_paths_array
    declare -A backup_map
    for entry in "${custom_paths_array[@]}"; do
        echo "$entry"
        # echo "${deserialized_mountpoint_repo_map["$entry"]}"
        backup_map["$entry"]="${deserialized_mountpoint_repo_map["$entry"]}"
        echo "${backup_map["$entry"]}"
    done




else
    echo "No custom paths provided"
    # Your default backup logic
fi








