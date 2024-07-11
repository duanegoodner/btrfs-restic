#!/bin/bash

serialize_map() {
    local -n map=$1
    local serialized_map=""

    for key in "${!map[@]}"; do
        serialized_map+="$key:${map[$key]} "
    done

    # Remove trailing comma
    serialized_map="${serialized_map%' '}"

    echo "$serialized_map"
}

deserialize_map() {
    local serialized_map=$1
    declare -n deserialized_array="$2"

    # Split the string by spaces
    IFS=' ' read -r -a entries <<< "$serialized_map"

    # Iterate over each entry
    for entry in "${entries[@]}"; do
        # Split the entry by ":"
        IFS=':' read -r key value <<< "$entry"
        # Add to associative array
        # shellcheck disable=SC2034
        deserialized_array["$key"]="$value"
    done
}

serialized_map_from_pairs_array() {
    local separator=":"
    local pairs_array=("${!1}")
    local var_name=$2
    local -A output_map
    local serialized_map

    for entry in "${pairs_array[@]}"; do
        IFS="$separator" read -r mount_point repo_name <<< "$entry"
        output_map["$mount_point"]="$repo_name"
    done

    serialized_map=$(serialize_map output_map)
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
    declare -n arr=$2
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


# serialized_map_from_pairs_array MOUNTPOINT_REPO_LIST[@] "SERIALIZED_MOUNTPOINT_REPO_MAP"
# echo "$SERIALIZED_MOUNTPOINT_REPO_MAP"

# alternate_serialized=$(serialize_array MOUNTPOINT_REPO_LIST[@])
# echo "$alternate_serialized"


# Capture the output into a string
# vals_str=$(get_vals "${MOUNTPOINT_REPO_LIST[@]}")

# Deserialize the string into an array
# deserialize_array "$vals_str" vals_list

# Now you can access the elements correctly
# echo "${vals_list[1]}"

# Serialize the array back into a string
# serialized_str=$(serialize_array vals_list[@])
# echo "$serialized_str"

# serialized_mountpoint_repo_list=$(serialize_array MOUNTPOINT_REPO_LIST[@] )
# echo "$serialized_mountpoint_repo_list"

# echo break
# deserialize_array "$serialized_mountpoint_repo_list" deserialized_mountpoint_repo_list
# echo "${deserialized_mountpoint_repo_list[@]}"

# latest quicktests end here

#################


# map_from_pairs_array MOUNTPOINT_REPO_LIST[@] ":" "MOUNTPOINT_REPO_MAP"
# echo "Serialized map stored in MOUNTPOINT_REPO_MAP: $MOUNTPOINT_REPO_MAP"

# declare -A deserialized_map
# deserialize_map "$MOUNTPOINT_REPO_MAP" deserialized_map

# echo "Deserialized map:"
# for key in "${!deserialized_map[@]}"; do
#     echo "$key => ${deserialized_map[$key]}"
# done


