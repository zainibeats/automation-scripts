# Network

Scripts for remote mounts and network/VPN checks.

Most scripts accept command-line options and also read a per-directory `.env`
file when present. Copy the relevant `.env.example` file to `.env` for repeated
local defaults.

## Remote Mounts

### `remote-mount/nfs-mount.sh`

Mounts an NFS share from a configured server.

Dependencies:

- `nfs-common` on Linux
- Root or sudo access

Usage:

```bash
sudo ./remote-mount/nfs-mount.sh --server-ip 192.168.1.100 --nfs-share /mnt/data --mount-point ~/remote-mount/nfs
```

Options and `.env` values:

- `SERVER_IP`
- `NFS_SHARE`
- `MOUNT_POINT`
- `NFS_OPTIONS`

### `remote-mount/sshfs-mount.sh`

Mounts a remote directory over SSH using `sshfs`.

Dependencies:

- `sshfs`
- SSH access to the configured server

Usage:

```bash
./remote-mount/sshfs-mount.sh --server username@192.168.1.100 --remote-path / --mount-dir ~/remote_mount/sshfs
```

Options and `.env` values:

- `SERVER`
- `REMOTE_PATH`
- `REMOTE_MOUNT_DIR`
- `PORT`

## VPN Check

### `vpn-check/mullvad-check.py`

Queries Mullvad's status endpoint and prints the current public IP, city,
country, and ISP through the local logger.

Dependencies:

- Python 3
- `curl`
- `vpn-check/logger.py`
