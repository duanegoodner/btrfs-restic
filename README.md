# btrfs_restic
Takes snapshots of BTRFS sub-volumes, then sends in a filesystem agnostic form to a remote restic repository.

## Requirements
- a Linux system with one or more BTRFS subvolumes
- btrfs-progs
- restic
- openssh
- user account on a remote server accessible by ssh

## Simple Example

In this example, our local machine has BTRFS subvolumes `@` mounted at `/`, and `@home` mounted at `/home`. We want to use local user `someuser` to periodically take BTRFS snapshots of these subvolumes, and send the snapshotted data as incremental backups to restic repositories located under `/srv/backups/my_machine` remote host `restic-server` at ip address `192.168.2.3` where we can access user account `resticuser`.


### 1. Set up passwordless ssh

#### a) Generate ssh key (if you don't already have one you want to use) 
```bash
someuser@local-machine$ ssh-keygen -t ed25519 -f ~/.ssh/for_restic_demo
#Enter passphrase (empty for no passphrase):S
#Enter same passphrase again:
```


#### b) Put your public key on `restic-server`

Your public key needs to be added to `/home/resticuser/.ssh/authorized_keys`. If password ssh access is allowed on `restic-server`, we can use:
```bash
someuser@local-machine$ ssh-copy-id -i ~/.ssh/for_restic_demo resticuser@192.168.2.3
```
If `resticuser` can't ssh to `restic-server` via password, we will need to use a more manual method to put our public key info in `/home/resticuser/.ssh/authorized_keys` on `restic-server`  (e.g. secure email, connecting as another user + copy-paste, etc.)

#### c) Update local ssh config to ensure restic uses ssh key for connection

On our local machine, add the following to `/home/someuser/.ssh/config` (create the file if it does not exist).

```bash
Host restic-server
        HostName 192.168.2.3
        User restic
        IdentityFile /home/someuser/.ssh/for_restic_demo
```

#### e) Add ssh key to our ssh agent
```bash
ssh-add /home/someuser/.ssh/for_restic_demo
# Enter passphrase for /home/someuser/.ssh/for_restic_demo: 
#Identity added: /home/someuser/.ssh/for_restic_demo (duane@orchard)
```

### 2. Set up restic repos on remote server

#### a) On the remote server, create the directories that will be used as restic repositories.

Note that each repository needs to have the same immediate parent directory (in this case, `/srv/backups/my_machine`).

```bash
someuser@local-machine$ ssh resticuser@restic-server

resticuser@restic-server$ mkdir -p /srv/backups/my_machine
resticuser@restic-server$ mkdir /srv/backups/my_machine/root
resticuser@restic-server$ mkdir /srv/backups/my_machine/home
resticuser@restic-server$ exit
```

#### b) Initialize the restic repositories

The remote server does not need to have restic installed. We initialize paths on the remote server as restic repositories by doing the following from our local machine:

```bash
someuser@local-machine$ restic -r sftp:restic_user@restic_server:/srv/backups/my_machine/root init
# enter password for new repository: 
# enter password again: 
# created restic repository 319a152f0d at /srv/backups/my_machine/root
#
# Please note that knowledge of your password is required to access
# the repository. Losing your password means that your data is
# irrecoverably lost.

someuser@local-machine$ restic -r sftp:restic_user@restic_server:/srv/backups/my_machine/@home init
# enter password for new repository: 
# enter password again: 
# created restic repository 728b152e1a at /srv/backups/my_machine/root
#
# Please note that knowledge of your password is required to access
# the repository. Losing your password means that your data is
# irrecoverably lost.

```



### 3. Put shell script and .env  






1. On the remote server, create a parent directory where restic repositories will be stored. Create a sub-directory for each local BTRFS subvolume you want to back up, and create a restic repository in each of these subdirectories.
    ```
    mkdir /path/to/restic/parent/dir
    mkdir /path/to/restic/parent/dir/
    ```
2. For each local BTRFS subvolume that you want to take snapshots/backups of, create a restic repository on the remote




