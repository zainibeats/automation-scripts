# Media

Scripts for downloading, preparing, and transferring audio/video files.

Most scripts accept command-line options and also read a per-directory `.env`
file when present. Copy the relevant `.env.example` file to `.env` for repeated
local defaults.

## Audio Transfer

Detailed notes live in [audio-transfer/README.md](audio-transfer/README.md).

Scripts:

- `audio-transfer/ssh-wav-mp3.sh` - transfers WAV/MP3 files to a remote server
  over SSH.
- `audio-transfer/ssh-wav-mp3-master-stems.sh` - transfers master audio files
  and related stems.

Dependencies:

- Bash
- SSH access for transfer scripts

Usage:

```bash
./audio-transfer/ssh-wav-mp3.sh /local/audio user@host:/remote/audio
./audio-transfer/ssh-wav-mp3-master-stems.sh /local/audio user@host:/remote/audio
```

## Downloads

### `downloads/single-dl.sh`

Downloads one video or audio item from a URL stored in `~/Documents/url.txt`.
Supports quality selection, automatic subtitles, title-based naming, numbered
fallback naming, and archive-based resume.

Usage:

```bash
./downloads/single-dl.sh --url-file ~/Documents/url.txt --quality 1080
```

### `downloads/batch-dl.sh`

Downloads URLs or playlists from `~/Documents/playlist.txt`. It tracks completed
downloads with an archive file and handles playlist index prefixes.

Usage:

```bash
./downloads/batch-dl.sh --url-file ~/Documents/playlist.txt --output-dir ~/Downloads/course
```
