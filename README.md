# btrfs-restic
Takes snapshots of BTRFS sub-volumes, then sends snapshotted data to a remote Restic repository. Does not require BTRFS on the remote.

## Project status
Fully functional. Some manual setup required, as outlined below. Refinement is ongoing as we learn from running actual backups. Also plan to add scripts to automate data restoration.

## Requirements
- Local system:
  - Linux machine with one or more BTRFS subvolumes. Packages: 
  - Packages: btrfs-progs, restic, openssh
- Remote Server
  - Packages: openssh-server

## Motivation

We want an automated scheme to take snapshots of BTRFS subvolumes on our local machine, and send this data to a remote backup server.

It is possible to send BTRFS snapshots to a remote host using `btrfs send` and `btrfs receive`. However, this approach requires that the remote use BTRFS, and automating the transfer process can be complicated unless we allow ssh login as `root` on the remote. 

Using Restic for data transfer is compatible with essentially any filesystem on the remote. Configuring Restic to send automated, incremental backups is relatively straightforward. Although Restic snapshots are not purely atomic, since we are sending data from BTRFS snapshots (which are atomic), the data transferred by Restic still represents the state of the local system at a single point in time.

## Example

In this example, our local machine has BTRFS subvolumes `@` mounted at `/`, and `@home` mounted at `/home`, and we have user account `resticuser` with sudo privileges on a remote server at ip address `192.168.2.3`.

### 1. Set up passwordless ssh

#### a) Generate ssh key pair and copy the puclic key to server
```
ssh-keygen -t ed25519 -f ~/.ssh/for_restic_demo
```

#### b) Copy public key to server

```
ssh-copy-id -i ~/.ssh/for_restic_demo resticuser@192.168.2.3
```

#### c) Update `~/.ssh/config` (recommended)

Add the following to `~/.ssh/config` (create file if it does not already exist)
```
Host restic-server
        HostName 192.168.2.3
        User restic
        IdentityFile /home/someuser/.ssh/for_restic_demo
```

#### d) Add ssh key to our ssh agent (recommended)

```
ssh-add /home/someuser/.ssh/for_restic_demo
```

### 2. Generate file with passord for Restic repositories

```
touch ~/securefolder/restic_repo_password
chmod 0600 ~/securefolder/restic_repo_password
pwgen -cnys 30 1 > ~/securefolder/restic_repo_password
```

### 3. Save copy of Restic binary with elevated read privileges

```
curl -L https://github.com/restic/restic/releases/download/v0.16.5/restic_0.16.5_linux_amd64.bz2 -o /tmp/restic_0.16.5_linux_amd64.bz2
bunzip2 /tmp/restic_0.16.5_linux_amd64.bz2
mv /tmp/restic_0.16.5_linux_amd64 ~/bin/restic
chmod 0700 ~/bin/restic
```
### 4. Allow local user to run certain BTRFS commands without password

```
sudo visudo
```
File `/etc/sudoers.tmp` should open in a terminal editor (likely `nano`). Add the following lines near the end of file:
```bash
someuser ALL=(ALL) NOPASSWD: /usr/bin/btrfs subvolume snapshot *
someuser ALL=(ALL) NOPASSWD: /usr/bin/btrfs subvolume delete /.tmp_snapshots/*
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
> # Allow someuser to delete btrfs subvolumes in the /.tmp_snapshots/ directory without a password
> someuser ALL=(ALL) NOPASSWD: /usr/bin/btrfs subvolume delete /.tmp_snapshots/*
> 
> # See sudoers(5) for more information on "@include" directives:
> 
> @includedir /etc/sudoers.d
> ```

### 5. Create local directory for temporary storage of BTRFS snapshots
For each subvolume we want to back up, our script created a BTRFS snapshot of that subvolume, sends the data to the restic repo, and then deletes the BTRFS snapshot. We need a fixed local location for these temporary snapshots for restic deduplication to work properly.

```
sudo mkdir /.tmp_snapshots
```

### 6. Enter values in `btrfs_restic.env`  
Create file `./etc/btrfs_restic.env` (Note the path is under the project root, not under `/etc`)  with the following variable assignments:

```shell
RESTIC_SERVER=192.168.2.3
RESTIC_SERVER_USER=resticuser
SSH_KEYFILE="$HOME"/.ssh/for_restic_demo
RESTIC_REPOS_DIR=/srv/backups/my_machine
RESTIC_REPOS_PASSWORD_FILE="$HOME"/securefolder/restic_repo_password
RESTIC_BINARY="$HOME"/bin/restic
BTRFS_SNAPSHOTS_DIR=/.tmp_snapshots
MOUNTPOINT_REPO_LIST=(
    "/:@"
    "/home:@home"
)
LOG_DIR=./logs
TIMESTAMP_LOG=false
```

- Each item in `BTRFS` subvolumes is entered as `<mount point>:<subvolume name>`. We can get info about our subvolumes and mount points with:
    ```
    sudo btrfs subolume list /
    sudo findmnt -nt btrfs
    ```

- The default value of `TIMESTAMP_LOG=false` results in no line-level timestamping in the log files, but log filenames will still contain timestamp info. Setting `TIMESTAMP_LOG=true` will print timestamps on each line of the log file but will prevent restic's realtime updates during repository scans from displaying in the terminal. For large data transfers, this may give a user the incorrect impression that the program is hanging / stuck.



### 7. Initialize remote repositories 

```
./bin/brestic init
```

### 8. Use `run_backup.sh` to take BTRFS snapshots and send

From the project root directory, we can run the shell script with:

```
./bin/brestic backup
```

The first time the script runs, output will look something like this:

<pre><code>Creating local btrfs snapshot
Create a snapshot of '/' in '/.tmp_snapshots/root'
Snapshot of / created at /.tmp_snapshots/root
Sending incremental back up of /.tmp_snapshots/root to sftp:resticuser@192.168.2.3:/srv/backups/my_machine/root
open repository
repository 76b8c9e7 opened (version 2, compression level auto)
created new cache in /home/someuser/.cache/restic
lock repository
no parent snapshot found, will read all files
load index files

start scan on [/.tmp_snapshots/root]
start backup on [/.tmp_snapshots/root]
<b style="color: red;">scan finished in 1.541s: 214906 files, 12.638 GiB

Files:       214906 new,     0 changed,     0 unmodified
Dirs:        15325 new,     0 changed,     0 unmodified
Data Blobs:  173603 new
Tree Blobs:  14033 new
Added to the repository: 9.056 GiB (3.948 GiB stored)

processed 214906 files, 12.638 GiB in 0:24</b>
snapshot 74d3f3e4 saved
Delete subvolume (no-commit): '/.tmp_snapshots/root'
Creating local btrfs snapshot
Create a snapshot of '/home' in '/.tmp_snapshots/home'
Snapshot of /home created at /.tmp_snapshots/home
Sending incrementsl back up of /.tmp_snapshots/home to sftp:restic@192.168.2.3:/srv/backups/my_machine/home
open repository
repository da8633e3 opened (version 2, compression level auto)
created new cache in /home/someuser/.cache/restic
lock repository
no parent snapshot found, will read all files
load index files

start scan on [/.tmp_snapshots/home]
start backup on [/.tmp_snapshots/home]
<b style="color: red;">scan finished in 1.096s: 154685 files, 20.819 GiB

Files:       154685 new,     0 changed,     0 unmodified
Dirs:        14329 new,     0 changed,     0 unmodified
Data Blobs:  136913 new
Tree Blobs:  12721 new
Added to the repository: 19.646 GiB (11.860 GiB stored)

processed 154685 files, 20.819 GiB in 1:23</b>
snapshot fcba43e9 saved
Delete subvolume (no-commit): '/.tmp_snapshots/home'
</code></pre>



If we run the shell script a second time, the output will be similar. However, assuming we did not make significant changes to our local files between the two runs, the second run's time and dat summery will look like this for the backup of `/`:
<pre><code>start backup on [/.tmp_snapshots/root]
<b style="color: green;">scan finished in 1.431s: 214907 files, 12.638 GiB

Files:           1 new,     1 changed, 214905 unmodified
Dirs:            0 new,     7 changed, 15318 unmodified
Data Blobs:      1 new
Tree Blobs:      8 new
Added to the repository: 88.900 KiB (51.873 KiB stored)

processed 214907 files, 12.638 GiB in 0:03</b>
snapshot 5b3a6ac4 saved
</code></pre>

and like this for the backup of `/home`:

<pre><code>
start backup on [/.tmp_snapshots/home]
<b style="color: green;">scan finished in 1.169s: 154763 files, 20.835 GiB

Files:         284 new,   128 changed, 154351 unmodified
Dirs:           14 new,    86 changed, 14243 unmodified
Data Blobs:    433 new
Tree Blobs:     99 new
Added to the repository: 68.053 MiB (34.121 MiB stored)

processed 154763 files, 20.835 GiB in 0:02</b>
snapshot c3a67556 saved
</code></pre>

Since restic backups are incremental with very fast data de-duplication, `Processsed Time` and `Data Added` values are much smaller for the second run

> [!NOTE]
> Each BTRFS snapshot is deleted after it's data is sent to the remote host.