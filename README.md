# btrfs_restic
Takes snapshots of BTRFS sub-volumes, then sends in a filesystem agnostic form to a remote restic repository.

## Requirements
- Local System: Linux machine with one or more BTRFS subvolumes
- Packages: btrfs-progs, restic, openssh
- Remote Server: has a user account accessible by ssh

## Example

In this example, our local machine has BTRFS subvolumes `@` mounted at `/`, and `@home` mounted at `/home`. We want to use local user `someuser` to periodically take BTRFS snapshots of these subvolumes and send the snapshotted data as incremental backups to restic repositories located under `/srv/backups/my_machine` remote host `restic-server` at ip address `192.168.2.3` where we can access user account `resticuser`.


### 1. Set up passwordless ssh

#### a) Generate ssh key (if you don't already have one you want to use) 
<pre><code><b style="color: green;">someuser@local-machine$</b> ssh-keygen -t ed25519 -f ~/.ssh/for_restic_demo
<span style="color: gray;">Enter passphrase (empty for no passphrase):
Enter same passphrase again:</span>
</code></pre>


#### b) Put your public key on `restic-server`

Your public key needs to be added to `/home/resticuser/.ssh/authorized_keys`. If password ssh access is allowed on `restic-server`, we can use:

<pre><code><b style="color: green;">someuser@local-machine$</b> ssh-copy-id -i ~/.ssh/for_restic_demo resticuser@192.168.2.3</code></pre>

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

<pre><code><b style="color: green;">someuser@local-machine$</b> ssh-add /home/someuser/.ssh/for_restic_demo
<span style="color: gray;">Enter passphrase for /home/someuser/.ssh/for_restic_demo:
Identity added: /home/someuser/.ssh/for_restic_demo (someuser@local-machine)</span>
</code></pre>


### 2. Set up restic repos on remote server

#### a) On the remote server, create the directories that will be used as restic repositories.

Note that each repository needs to have the same immediate parent directory (in this case, `/srv/backups/my_machine`).

<pre><code><b style="color: green;">someuser@local-machine$</b> ssh resticuser@restic-server
<b style="color: orange;">resticuser@restic-server$</b> mkdir -p /srv/backups/my_machine
<b style="color: orange;">resticuser@restic-server$</b> mkdir /srv/backups/my_machine/root
<b style="color: orange;">resticuser@restic-server$</b> mkdir /srv/backups/my_machine/home
<b style="color: orange;">resticuser@restic-server$</b> exit
</code></pre>



#### b) Initialize the restic repositories

The remote server does not need to have restic installed. We initialize paths on the remote server as restic repositories by doing the following from our local machine. We use the same password for all repositories.

<pre><code><b style="color: green;">someuser@local-machine$</b> restic -r sftp:restic_user@restic_server:/srv/backups/my_machine/root init
<span style="color: gray;">enter password for new repository:
enter password again:
created restic repository 319a152f0d at /srv/backups/my_machine/root

Please note that knowledge of your password is required to access
the repository. Losing your password means that your data is
irrecoverably lost.</span>

<b style="color: green;">someuser@local-machine$</b> restic -r sftp:restic_user@restic_server:/srv/backups/my_machine/home init
<span style="color: gray;">enter password for new repository:
enter password again:
created restic repository 728b152e1a at /srv/backups/my_machine/root

Please note that knowledge of your password is required to access
the repository. Losing your password means that your data is
irrecoverably lost.</span>
</code></pre>


### 3. Save repository password to a local file


<pre><code><b style="color: green;">someuser@local-machine$</b>  touch /home/someuser/securefolder/restic_repo_password
<b style="color: green;">someuser@local-machine$</b>  chmod 0600 /home/someuser/securefolder/restic_repo_password
<b style="color: green;">someuser@local-machine$</b>  echo "password-for-restic-repos" > /home/someuser/securefolder/restic_repo_password
<span style="color: gray;"># Replace "pssword-for-restic-repos" with the password used when creating restic repositories</span>
</code></pre>

### 4. Create local directory for temporary storage of BTRFS snapshots
For each subvolume we want to back up, our script created a BTRFS snapshot of that subvolume, sends the data to the restic repo, and then deletes the BTRFS snapshot. We need a fixed local location for these temporary snapshots for restic deduplication to work properly.

<pre><code><b style="color: green;">someuser@local-machine$</b> sudo mkdir /.tmp_snapshots</code></pre>


### 5. Create local directory for log files

<pre><code><b style="color: green;">someuser@local-machine$</b> mkdir /home/someuser/.btrfs_restic_logs</code></pre>


### 6. Allow local user to run certain BTRFS commands without password

<pre><code><b style="color: green;">someuser@local-machine$</b> sudo visudo</code></pre>

File `/etc/sudoers.tmp` should open in a terminal editor (likely `nano`). Add the following lines near the end of file:
```bash
someuser ALL=(ALL) NOPASSWD: /usr/bin/btrfs subvolume snapshot *
someuser ALL=(ALL) NOPASSWD: /usr/bin/btrfs subvolume delete /.snapshots_tmp_restic/*
```
> [!IMPORTANT]
> Order of entries in the `sudoers` files matters. If our original file looks like this:
> ```
> # User privilege specification
> root    ALL=(ALL:ALL) ALL
>
> # Allow members of group sudo to execute any command
> %sudo   ALL=(ALL:ALL) ALL
>
> # User alias specification
> 
> # See sudoers(5) for more information on "@include" directives:
> 
> @includedir /etc/sudoers.d
> ```
> then modifying to this should work:
> ```
> # User privilege specification
> root    ALL=(ALL:ALL) ALL
> 
> # Allow members of group sudo to execute any command
> %sudo   ALL=(ALL:ALL) ALL
> 
> # User alias specification
> 
> # Allow someuser to take btrfs subvolume snapshots without a password
> someuser ALL=(ALL) NOPASSWD: /usr/bin/btrfs subvolume snapshot *
> 
> # Allow someuser to delete btrfs subvolumes in the /.snapshots_tmp_restic/ directory without a password
> someuser ALL=(ALL) NOPASSWD: /usr/bin/btrfs subvolume delete /.snapshots_tmp_restic/*
> 
> # See sudoers(5) for more information on "@include" directives:
> 
> @includedir /etc/sudoers.d
> ```


### 7. Enter values in `btrfs_restic.env`  
```shell
RESTIC_SERVER=192.168.2.3
RESTIC_SERVER_USER=restic
SSH_KEYFILE=/home/someuser/.ssh/for_restic_demo
RESTIC_REPOS_DIR=/srv/backups/my_machine/
RESTIC_REPOS_PASSWORD_FILE=/home/someuser/securefolder/restic_repo_password
LOG_DIR=/home/someuser/.btrfs_restic_logs
BTRFS_SNAPSHOTS_DIR=/.tmp_snapshots
BTRFS_SUBVOLUMES=(
    "/=@"
    "/home=@home"
)
```

### 8. Run `btrfs_restic.sh`

<pre><code><b style="color: green;">someuser@local-machine$</b> ./btrfs_restic.sh</pre></code>

