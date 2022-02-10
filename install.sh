#!/bin/bash

# Ensure the script directory is the current working directory
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "$SCRIPT_DIR"

# Create backup of original plex transcoder
if [ ! -f "/usr/lib/plexmediaserver/Plex Transcoder Backup" ]; then
  sudo cp -p "/usr/lib/plexmediaserver/Plex Transcoder" "/usr/lib/plexmediaserver/Plex Transcoder Backup"
  if [ ! -f "/usr/lib/plexmediaserver/Plex Transcoder Backup" ]; then
    echo "Failed to create backup of the original plex transcoder!"
    exit 1
  fi
fi

# Replace currently existing plex transcoder by a symlink to the wrapper script
sudo rm -f "/usr/lib/plexmediaserver/Plex Transcoder"
if [ -f "/usr/lib/plexmediaserver/Plex Transcoder" ]; then
  echo "Failed to remove original plex transcoder!"
  exit 1
fi
sudo ln -s "$SCRIPT_DIR/ffmpeg-transcode" "/usr/lib/plexmediaserver/Plex Transcoder"
if [ -f "/usr/lib/plexmediaserver/Plex Transcoder" ]; then
  echo "Wrapper script successfully installed!"
else
  echo "Failed to create symlink to wrapper script!"
  exit 1
fi
