# btrfs_restic
Takes snapshots of BTRFS sub-volumes, then sends in a filesystem agnostic form to a remote restic repository.

## Requirements
- a Linux system with one or more BTRFS subvolumes
- packages: btrfs-progs, restic
- user account on a remote server accessible by ssh

## Set Up
1. On the remote server, create a parent directory where restic repositories will be stored.
    ```
    mkdir /path/to/restic/parent/dir

    ```
2. For each local BTRFS subvolume that you want to take snapshots/backups of, create a restic repository on the remote




