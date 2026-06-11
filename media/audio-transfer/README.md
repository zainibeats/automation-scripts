# Audio Transfer Scripts

This directory contains scripts for transferring audio files, such as WAV and MP3, to remote servers.

## Scripts

- **ssh-wav-mp3.sh**: Transfers audio files (WAV/MP3) to a remote server via SSH.
- **ssh-wav-mp3-master-stems.sh**: Transfers master audio files and handles stem files for advanced workflows.

## Requirements
- Bash shell
- SSH access (for transfer scripts)

## Usage
Pass the source and destination directly:

```bash
./ssh-wav-mp3.sh /local/audio user@host:/remote/audio
./ssh-wav-mp3-master-stems.sh /local/audio user@host:/remote/audio
```

For repeated defaults, copy `.env.example` to `.env` in this directory and set:

- `SOURCE_DIR`
- `DEST_SSH`

Run either script with `--help` for all options.
