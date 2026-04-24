# Automation Scripts

A collection of bash and python scripts for automating remote desktop connections, network mounts, media downloads, and more.

---

## Remote Desktop (RDP)

Scripts for connecting to Windows/Remote Desktop environments.

### `freerdp/xfreerdp.sh`
Automates a full-screen RDP session with predefined credentials.
- **Dependencies:** 
  - `xfreerdp`

---

## Network Mounts

Scripts to automate mounting remote filesystems via NFS or SSHFS.

### `remote_mount/nfs-mount.sh`
Mounts an NFS share from a specified server. **Note: Requires root privileges.**
- **Dependencies:** 
  - `nfs-common` (on Linux)
  - Root/Sudo access

### `remote_mount/sshfs-mount.sh`
Mounts a remote directory over SSH using `sshfs`.
- **Dependencies:** 
  - `sshfs`

---

## Media Downloads (`yt-dlp`)

Scripts for downloading videos and audio from various platforms.

### `yt-dlp/single-dl.sh`
Downloads a single video or audio track from a URL stored in `~/Documents/url`. Mirrors the same config and logic as `batch-dl.sh` — supports quality selection, auto subtitles, title vs. numbered output naming, and archive-based resume — without playlist or batch iteration.
- **Dependencies:** 
  - Python 3
  - `pip install "yt-dlp[default,curl-cffi]"`
  - `ffmpeg`

### `yt-dlp/batch-dl.sh`
Downloads multiple URLs or entire playlists from a text file (`~/Documents/playlist.txt`). Handles archiving to prevent duplicate downloads, playlist index prefixing, and falls back to numbered naming when title extraction fails.
- **Dependencies:** 
  - Python 3
  - `pip install "yt-dlp[default,curl-cffi]"`
  - `ffmpeg`

---

## Network Utilities

### `mullvad-check/mullvad-check.py`
A lightweight Python script that queries the Mullvad status endpoint to reveal your current public IP, location, and ISP. It is handy for quickly verifying that a VPN connection is active.

- **Dependencies:**
  - Python 3
  - `curl` (used internally via subprocess)
  - Basic logging setup (`logger` module expected in the project root).
