#!/bin/bash

remote_mount_dir="$HOME/remote_mount/sshfs"

if [ ! -d "$remote_mount_dir" ]; then
  mkdir -p "$remote_mount_dir"
  echo "Created remote mount directory: $remote_mount_dir"
fi

server="username@192.168.1.100"
port="22"
mount_command="sshfs -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3,allow_other -p $port $server:/ $remote_mount_dir"

if mountpoint -q "$remote_mount_dir"; then
  echo "Remote mount already exists. Skipping mount."
else
  echo "Mounting remote filesystem"

  (
    bash -c "$mount_command"
    if [[ $? -eq 0 ]]; then
        echo "Remote filesystem mounted successfully at $remote_mount_dir"
    else
        echo "Error mounting remote filesystem. Check your connection and credentials."
        exit 1
    fi
  )
fi

if mountpoint -q "$remote_mount_dir"; then
  echo "Remote mount verified."
else
  echo "Remote mount failed.  Exiting."
  exit 1
fi
