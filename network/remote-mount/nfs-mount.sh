#!/bin/bash

# NFS Auto-Mount Script
# Configure the variables below, then run

### START CONFIGURATION ###
SERVER_IP="192.168.1.100"       # Change to your NFS server IP
NFS_SHARE="/mnt/data/jellyfin"      # Change to your NFS share path
MOUNT_POINT="$HOME/remote-mount/nfs"    # Change to your local mount directory
NFS_OPTIONS=""            # Change mount options if needed (e.g., "vers=3,nolock")
### END CONFIGURATION ###

# Check root privileges
if [ "$(id -u)" -ne 0 ]; then
    echo "Error: This script must be run as root. Use: sudo $0"
    exit 1
fi

# Validate configuration
if [ -z "$SERVER_IP" ] || [ -z "$NFS_SHARE" ] || [ -z "$MOUNT_POINT" ]; then
    echo "Error: Configuration incomplete. Please set all variables."
    exit 1
fi

# Create mount point if needed
echo "Checking mount point: $MOUNT_POINT"
if [ ! -d "$MOUNT_POINT" ]; then
    echo "Creating directory: $MOUNT_POINT"
    mkdir -p "$MOUNT_POINT" || exit 1
fi

# Check if already mounted
if mount | grep -q "$MOUNT_POINT"; then
    echo "Error: $MOUNT_POINT is already mounted"
    mount | grep "$MOUNT_POINT"
    exit 1
fi

# Perform the mount
echo "Mounting $SERVER_IP:$NFS_SHARE to $MOUNT_POINT..."
mount -t nfs -o "$NFS_OPTIONS" "$SERVER_IP:$NFS_SHARE" "$MOUNT_POINT"

# Verify success
if [ $? -eq 0 ]; then
    echo -e "\nMount successful!"
    echo "Share: $SERVER_IP:$NFS_SHARE"
    echo "Location: $MOUNT_POINT"
    df -hT | grep -w "$MOUNT_POINT"
else
    echo -e "\nError: Mount operation failed!"
    echo "Check:"
    echo "1. Server accessibility: ping $SERVER_IP"
    echo "2. NFS service status on server"
    echo "3. Export permissions on server"
    echo "4. Client NFS packages (nfs-common installed?)"
    exit 1
fi
