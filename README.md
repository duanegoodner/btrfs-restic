# btrfs_restic
Takes snapshots of BTRFS sub-volumes, then sends in a filesystem agnostic form to a remote restic repository.

## Requirements
- Local System: Linux machine with one or more BTRFS subvolumes
- Packages: btrfs-progs, restic, openssh
- Remote Server: has a user account accessible by ssh

## Example

In this example, we have the following scenario:
- `local-machine` has BTRFS subvolumes `@` mounted at `/`, and `@home` mounted at `/home`.
- User account `someuser` on `local-machine`
- Remote host `restic-server` at ip address `192.168.2.3` with user account `resticuser` that is a member of the `sudo` group. If this user does not have sudo privileges, there are workarounds, but we willl  not cover those here.


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

<pre><code><b style="color: green;">someuser@local-machine$</b> ssh resticuser@192.168.2.3
<b style="color: orange;">resticuser@restic-server$</b> sudo mkdir -p /srv/backups/my_machine
<b style="color: orange;">resticuser@restic-server$</b> sudo chown resticuser:resticuser /srv/backups/my_machine
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

### 5. Allow local user to run certain BTRFS commands without password

<pre><code><b style="color: green;">someuser@local-machine$</b> sudo visudo</code></pre>

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

### 6. Enter values in `btrfs_restic.env`  
```shell
RESTIC_SERVER=192.168.2.3
RESTIC_SERVER_USER=resticuser
SSH_KEYFILE=/home/someuser/.ssh/for_restic_demo
RESTIC_REPOS_DIR=/srv/backups/my_machine/
RESTIC_REPOS_PASSWORD_FILE=/home/someuser/securefolder/restic_repo_password
BTRFS_SNAPSHOTS_DIR=/.tmp_snapshots
BTRFS_SUBVOLUMES=(
    "/=@"
    "/home=@home"
)
LOG_DIR=./logs
TIMESTAMP_LOG=false
```


- Each item in `BTRFS` subvolumes is entered as `<mount point>=<subvolume name>`. We can get info about our subvolumes and mount points with:
    <pre><code><b style="color: green;">someuser@local-machine$</b> sudo btrfs subolume list /
    <b style="color: green;">someuser@local-machine$</b> sudo findmnt -nt btrfs
    </pre></code>

- `btrfs_restic.sh` expects a `btrfs_restic.env` to be in the same directory as `btrfs_restic.sh`. If you want the `.env` file to be in a different location, modify line `DOT_ENV_FILE=btrfs_restic.env` in `btrfs_restic.sh`.

- The default value of `LOG_DIR=./logs` causes log files to written to a `logs` sub-directory that is a sibling to `btrfs_restic.sh`.

- The default value of `TIMESTAMP_LOG=false` results in no line-level timestamping in the log files, but log filenames will still contain timestamp info. Setting `TIMESTAMP_LOG=true` will print timestamps on each line of the log file but will prevent restic's realtime updates during repository scans from displaying in the terminal. For large data transfers, this may give a user the incorrect impression that the program is hanging / stuck.

### 7. Run `btrfs_restic.sh`

From the project root directory, we can run the shell script with:

<pre><code><b style="color: green;">someuser@local-machine$</b> ./btrfs_restic.sh</pre></code>

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

The `scan finished` times for the backup of `/` are similar (1.541 seconds vs. 1.431 seconds), but since restic allows incremental backups with very fast de-duplication, the `processsed` time and data `Added to the repository` values are much smaller for the second run (24 s / 9.056 GiB vs. 3 s / 88.900 KiB) 

Looking at the output from the second-run backup of `/home` we similar


<style>
  table {
    border-collapse: collapse;
    width: 100%;
  }
  th, td {
    border: 1px solid black;
    padding: 8px;
    text-align: left;
  }
  th {
    background-color: #f2f2f2;
  }
  .center {
    text-align: center;
  }
</style>

<table>
  <thead>
    <tr>
      <th rowspan="2">Run #</th>
      <th colspan="2" class="center">Root</th>
      <th colspan="2" class="center">Home</th>
    </tr>
    <tr>
      <th>Processed Time</th>
      <th>Data Added</th>
      <th>Processed Time</th>
      <th>Data Added</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>1</td>
      <td>24 sec</td>
      <td>12.638 GiB</td>
      <td>83 s</td>
      <td>19.646 GiB</td>
    </tr>
    <tr>
      <td>2</td>
      <td>3 s</td>
      <td>88.900 KiB</td>
      <td>2 s</td>
      <td>68.053 MiB</td>
    </tr>
  </tbody>
</table>