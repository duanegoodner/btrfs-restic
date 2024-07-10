#!/bin/bash

serialize_map() {
    local -n map=$1
    local serialized_map=""

    for key in "${!map[@]}"; do
        serialized_map+="$key=${map[$key]},"
    done

    # Remove trailing comma
    serialized_map="${serialized_map%,}"

    echo "$serialized_map"
}

deserialize_map() {
    local serialized_map=$1
    local -n map=$2
    local IFS=','

    read -ra entries <<< "$serialized_map"
    for entry in "${entries[@]}"; do
        IFS='=' read -r key value <<< "$entry"
        map["$key"]="$value"
    done
}

map_from_pairs_array() {
    local separator="${2:-:}"
    local pairs_array=("${!1}")
    local var_name=$3
    local -A output_map

    for entry in "${pairs_array[@]}"; do
        IFS="$separator" read -r mount_point repo_name <<< "$entry"
        output_map["$mount_point"]="$repo_name"
    done

    local serialized_map=$(serialize_map output_map)
    eval export "$var_name"="'$serialized_map'"
}

get_vals() {
    local array=("$@")
    local values=()
    
    for item in "${array[@]}"; do
        IFS=":" read -r _ value <<< "$item"
        values+=("$value")
    done
    
    echo "${values[@]}"
}

deserialize_array() {
    local str="$1"
    local -n arr=$2
    IFS=' ' read -r -a arr <<< "$str"
}

serialize_array() {
    local arr_name="$1"
    local arr=("${!arr_name}")
    local str="${arr[*]}"
    echo "$str"
}

# Example usage
MOUNTPOINT_REPO_LIST=(
  "/:@"
  "/home:@home"
  "/var/log:@var_log"
  "/var/cache:@var_cache"
  "/var/spool:@var_spool"
  "/var/tmp:@var_tmp"
)

# Capture the output into a string
vals_str=$(get_vals "${MOUNTPOINT_REPO_LIST[@]}")

# Deserialize the string into an array
deserialize_array "$vals_str" vals_list

# Now you can access the elements correctly
echo "${vals_list[1]}"

# Serialize the array back into a string
serialized_str=$(serialize_array vals_list[@])
echo "$serialized_str"

# vals_list_str=$(get_vals "${MOUNTPOINT_REPO_LIST[@]}")
# vals_list_array=$(deserialize_array "$vals_list_str")


# serialized_mountpoint_repo_list=$(serialize_array "${MOUNTPOINT_REPO_LIST[@]}")
# echo "$serialized_mountpoint_repo_list"

# echo break
# deserialized_mountpoint_repo_list=$(deserialize_array "$serialized_mountpoint_repo_list")
# echo "$deserialized_mountpoint_repo_list"

# get_vals MOUNTPOINT_REPO_LIST[@] SUBVOL_LIST_STR
# echo "$SUBVOL_LIST_STR"

# map_from_pairs_array MOUNTPOINT_REPO_LIST[@] ":" "MOUNTPOINT_REPO_MAP"
# echo "Serialized map stored in MOUNTPOINT_REPO_MAP: $MOUNTPOINT_REPO_MAP"

# declare -A deserialized_map
# deserialize_map "$MOUNTPOINT_REPO_MAP" deserialized_map

# echo "Deserialized map:"
# for key in "${!deserialized_map[@]}"; do
#     echo "$key => ${deserialized_map[$key]}"
# done

# get_vals MOUNTPOINT_REPO_LIST[@] MY_VALS
# echo "$MY_VALS"


