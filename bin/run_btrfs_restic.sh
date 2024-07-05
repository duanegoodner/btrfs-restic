#!/bin/bash

# shellcheck source=./btrfs_restic_helpers.sh
source btrfs_restic_helpers.sh

load_dot_env "$DOT_ENV_FILE"
check_preconditions
create_log_file
run_backup