# Media

Scripts for downloading, preparing, and transferring audio/video files.

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

## Downloads

### `downloads/single-dl.sh`

Downloads one video or audio item from a URL stored in `~/Documents/url.txt`.
Supports quality selection, automatic subtitles, title-based naming, numbered
fallback naming, and archive-based resume.

### `downloads/batch-dl.sh`

Downloads URLs or playlists from `~/Documents/playlist.txt`. It tracks completed
downloads with an archive file and handles playlist index prefixes.
