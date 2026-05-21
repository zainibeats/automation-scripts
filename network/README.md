# Network

Scripts for remote mounts and network/VPN checks.

## Remote Mounts

### `remote-mount/nfs-mount.sh`

Mounts an NFS share from a configured server.

Dependencies:

- `nfs-common` on Linux
- Root or sudo access

Configure these values before running:

- `SERVER_IP`
- `NFS_SHARE`
- `MOUNT_POINT`
- `NFS_OPTIONS`

### `remote-mount/sshfs-mount.sh`

Mounts a remote directory over SSH using `sshfs`.

Dependencies:

- `sshfs`
- SSH access to the configured server

Configure these values before running:

- `remote_mount_dir`
- `server`
- `port`

## VPN Check

### `vpn-check/mullvad-check.py`

Queries Mullvad's status endpoint and prints the current public IP, city,
country, and ISP through the local logger.

Dependencies:

- Python 3
- `curl`
- `vpn-check/logger.py`
