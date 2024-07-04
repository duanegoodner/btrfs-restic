# btrfs_restic
Takes snapshots of BTRFS sub-volumes, then sends in a filesystem agnostic form to a remote restic repository.

## Requirements
- a Linux system with one or more BTRFS subvolumes
- btrfs-progs
- restic
- openssh
- user account on a remote server accessible by ssh

## Simple Example

On our local system, we have BTRFS subvolumes `@` mounted at `/`, and `@home` mounted at `/home`. We want to periodically take BTRFS snapshots of these subvolumes, and send the snapshotted data as incremental backups to restic repositories located under `/srv/backups/my_machine` on remote server `restic-server` where we can access user account `resticuser`.


### Set up passwordless ssh

#### 1. Generate ssh key (if you don't already have one you want to use) 
```
someuser@local-machine$ ssh-keygen -t ed25519 -f ~/.ssh/for_restic_demo
Enter passphrase (empty for no passphrase): 
Enter same passphrase again:
```

#### 2. Put your public key on `restic-server`

The content of your public key needs to be entered as a single line in `/home/resticuser/.ssh/authorized_keys`. If password ssh access is allowed on `restic-server`, we can use:
```
someuser@local-machine$ ssh-copy-id -i ~/.ssh/for_restic_demo resticuser@restic-server
```
If `resticuser` can't ssh to `restic-server` via password, we will need use a more manual methodto put our public key info in `/home/resticuser/.ssh/authorized_keys` on `restic-server`  (e.g. secure email, connecting as another user + copy-paste, etc.)

#### 3. 






### Set up restic repos on remote server

```
someuser@local-machine$ ssh resticuser@restic-server

resticuser@restic-server$ mkdir -p /srv/backups/my_machine
resticuser@restic-server$ mkdir /srv/backups/my_machine/root
resticuser@restic-server$ mkdir /srv/backups/my_machine/home
resticuser@restic-server$ exit

someuser@local-machine$ restic -r sftp:restic_user@restic_server:/srv/backups/my_machine/@ init
someuser@local-machine$ restic -r sftp:restic_user@restic_server:/srv/backups/my_machine/@home init

```




### 






1. On the remote server, create a parent directory where restic repositories will be stored. Create a sub-directory for each local BTRFS subvolume you want to back up, and create a restic repository in each of these subdirectories.
    ```
    mkdir /path/to/restic/parent/dir
    mkdir /path/to/restic/parent/dir/
    ```
2. For each local BTRFS subvolume that you want to take snapshots/backups of, create a restic repository on the remote




