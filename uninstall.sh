#!/bin/bash

# Ensure the script directory is the current working directory
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "$SCRIPT_DIR"

# Create backup of original plex transcoder
if [ ! -f "/usr/lib/plexmediaserver/Plex Transcoder Backup" ]; then
  echo "No backup of the original plex transcoder found! Can't uninstall!"
  exit 1
fi

# Replace currently existing plex transcoder by a symlink to the wrapper script
sudo rm -f "/usr/lib/plexmediaserver/Plex Transcoder"
if [ -f "/usr/lib/plexmediaserver/Plex Transcoder" ]; then
  echo "Failed to remove wrapper plex transcoder!"
  exit 1
fi
sudo mv "/usr/lib/plexmediaserver/Plex Transcoder Backup" "/usr/lib/plexmediaserver/Plex Transcoder"
if [ -f "/usr/lib/plexmediaserver/Plex Transcoder" ]; then
  echo "Wrapper script successfully uninstalled!"
else
  echo "Failed to restore original plex transcoder backup!"
  exit 1
fi
