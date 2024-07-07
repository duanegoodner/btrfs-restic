#! /bin/bash

if [ -d "$RESTIC_REPOS_DIR" ]; then
    echo "Warning: $RESTIC_REPOS_DIR already exists. Proceeding with subdirectory creation" 
else
    sudo mkdir -p "$RESTIC_REPOS_DIR"
    sudo chown "$USER":"$USER" "$RESTIC_REPOS_DIR"
    echo "Directory $RESTIC_REPOS_DIR created"
fi

# Convert SUBVOL_LIST_STR back into an array
IFS=' ' read -r -a SUBVOL_LIST <<< "$SUBVOL_LIST_STR"

for subvol in "${SUBVOL_LIST[@]}"; do
    if [ -d "${RESTIC_REPOS_DIR}/${subvol}" ]; then
        echo "Warning: ${RESTIC_REPOS_DIR}/${subvol} already exists"
    else
        mkdir "${RESTIC_REPOS_DIR}/${subvol}"
        chown -R "$RESTIC_SERVER_USER":"$RESTIC_SERVER_USER" "${RESTIC_REPOS_DIR}/${subvol}"
        echo "Created ${RESTIC_REPOS_DIR}/${subvol}"
    fi
done