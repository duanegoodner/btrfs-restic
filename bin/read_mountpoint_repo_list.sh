#!/bin/bash

declare -A MOUNTPOINT_REPO_MAP

build_mountpoint_repo_map() {
    local -n mountpoint_repo_list=$1

    for entry in "${mountpoint_repo_list[@]}"; do
        echo running!
        IFS=':' read -r mount_point repo_name <<<"$entry"
        MOUNTPOINT_REPO_MAP[$mount_point]=$repo_name
    done

}

MOUNTPOINT_REPO_LIST=(
  "/:@"
  "/home:@home"
  "/var/log:@var_log"
  "/var/cache:@var_cache"
  "/var/spool:@var_spool"
  "/var/tmp:@var_tmp"
)

build_mountpoint_repo_map MOUNTPOINT_REPO_LIST
echo "${MOUNTPOINT_REPO_MAP[/home]}"



