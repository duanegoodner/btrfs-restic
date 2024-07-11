#!/bin/bash

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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
        --paths=*) custom_paths="${1#*=}" ;;
        *)
            echo "Unknown parameter passed: $1"
            exit 1
            ;;
        esac
        shift
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

load_dot_env "$dot_env_file"

# # Call the argument_collector function
get_args "$@"

get_backup_map
