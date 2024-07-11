#! /bin/bash

# Creates directories (to be used as Restic repos) on server
# This script is part of the ssh command that runs on the server (sent in server_init.sh)

if [ -d "$RESTIC_REPOS_DIR" ]; then
    echo "Warning: $RESTIC_REPOS_DIR already exists. Proceeding with subdirectory creation" 
else
    sudo mkdir -p "$RESTIC_REPOS_DIR"
    sudo chown "$USER":"$USER" "$RESTIC_REPOS_DIR"
    echo "Directory $RESTIC_REPOS_DIR created"
fi

declare -a SUBVOL_LIST
deserialize_array "$SUBVOL_LIST_SERIALIZED" SUBVOL_LIST

for subvol in "${SUBVOL_LIST[@]}"; do
    if [ -d "${RESTIC_REPOS_DIR}/${subvol}" ]; then
        echo "Warning: ${RESTIC_REPOS_DIR}/${subvol} already exists"
    else
        mkdir "${RESTIC_REPOS_DIR}/${subvol}"
        chown -R "$RESTIC_SERVER_USER":"$RESTIC_SERVER_USER" "${RESTIC_REPOS_DIR}/${subvol}"
        echo "Created ${RESTIC_REPOS_DIR}/${subvol}"
    fi
done