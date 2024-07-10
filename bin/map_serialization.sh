#!/bin/bash

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

build_mountpoint_repo_map() {
    local mountpoint_repo_list=("$@")
    local -A mountpoint_repo_map

    for entry in "${mountpoint_repo_list[@]}"; do
        IFS=':' read -r mount_point repo_name <<< "$entry"
        mountpoint_repo_map["$mount_point"]="$repo_name"
    done

    export MOUNTPOINT_REPO_MAP=$(serialize_map mountpoint_repo_map)
}

MOUNTPOINT_REPO_LIST=(
  "/:@"
  "/home:@home"
  "/var/log:@var_log"
  "/var/cache:@var_cache"
  "/var/spool:@var_spool"
  "/var/tmp:@var_tmp"
)

build_mountpoint_repo_map "${MOUNTPOINT_REPO_LIST[@]}"

echo "Serialized map: $MOUNTPOINT_REPO_MAP"

declare -A deserialized_map
deserialize_map "$MOUNTPOINT_REPO_MAP" deserialized_map

echo "Deserialized map:"
for key in "${!deserialized_map[@]}"; do
    echo "$key => ${deserialized_map[$key]}"
done
