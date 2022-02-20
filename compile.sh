#!/bin/bash

set -e

# System information
SYSTEM_DISTRO=`lsb_release -s -i`

# Settings for the compile script
APT_COMMAND="apt install"
APT_INSTALL_PACKAGES=""
FFMPEG_CONFIGURE_FLAGS='--extra-cflags="-I/usr/local/include" --extra-ldflags="-L/usr/local/lib" --extra-libs="-lpthread -lm -latomic" --enable-gmp --enable-gpl --enable-libaom --enable-libass --enable-libdav1d --enable-libfreetype --enable-libmp3lame --enable-libopencore-amrnb --enable-libopencore-amrwb --enable-libopus --enable-librtmp --enable-libsnappy --enable-libsoxr --enable-libssh --enable-libvorbis --enable-libvpx --enable-libwebp --enable-libx264 --enable-libx265 --enable-libxml2 --enable-mmal --enable-eae --enable-nonfree --enable-version3 --target-os=linux --enable-pthreads --enable-openssl --enable-hardcoded-tables'

# Track tasks
EXTRACT_SOURCE="no"
INSTALL_DEPENDENCIES="yes"
FFMPEG_COMPILE="no"

# Ensure the script directory is the current working directory
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "$SCRIPT_DIR"

# Prepare dependencies for the used distribution
case $SYSTEM_DISTRO in
  Raspbian)
    APT_INSTALL_PACKAGES="python3 python3-yaml libass-dev libaom-dev libxvidcore-dev libvorbis-dev libv4l-dev libx265-dev libx264-dev libwebp-dev libspeex-dev librtmp-dev libopus-dev libmp3lame-dev libdav1d-dev libopencore-amrnb-dev libopencore-amrwb-dev libsnappy-dev libsoxr-dev libssh-dev libxml2-dev"
    ;;
  ManjaroLinux)
    APT_COMMAND="pamac install"
    APT_INSTALL_PACKAGES="yasm make pkgconf python python-yaml libass aom xvidcore libvorbis libv4l x265 x264 libwebp speex librtmp0 opus dav1d opencore-amr snappy libsoxr libssh libxml2"
    FFMPEG_CONFIGURE_FLAGS='--extra-cflags="-I/usr/include" --extra-ldflags="-L/usr/lib" --extra-libs="-lpthread -lm -latomic" --enable-gmp --enable-gpl --enable-libaom --enable-libass --enable-libdav1d --enable-libfreetype --enable-libmp3lame --enable-libopencore-amrnb --enable-libopencore-amrwb --enable-libopus --enable-librtmp --enable-libsnappy --enable-libsoxr --enable-libssh --enable-libvorbis --enable-libvpx --enable-libwebp --enable-libx264 --enable-libx265 --enable-libxml2 --enable-eae --enable-nonfree --enable-version3 --target-os=linux --enable-pthreads --enable-openssl --enable-hardcoded-tables'
    ;;
  *)
    echo "Unsupported linux distribution: $SYSTEM_DISTRO"
    echo "!!! DEPENDENCIES WILL NOT BE INSTALLED - YOU WILL HAVE TO OBTAIN THEM MANUALLY !!!"
    echo "$APT_INSTALL_PACKAGES" > "$SCRIPT_DIR/apt-packages-installed"
    ;;
esac

# URL for the source code of the plex ffmpeg-fork
PLEX_FFMPEG_SOURCE_URL="https://downloads.plex.tv/ffmpeg-source/plex-media-server-ffmpeg-gpl-62cc2bc17d.tar.gz"
if [ -f "/usr/lib/plexmediaserver/Resources/LICENSE" ]; then
  PLEX_FFMPEG_SOURCE_URL=`cat /usr/lib/plexmediaserver/Resources/LICENSE | grep 'Plex Transcoder' | sed 's/.*: //'`
fi
PLEX_FFMPEG_SOURCE_URL_PRESENT=""
if [ -f "$SCRIPT_DIR/ffmpeg-source-url" ]; then
  PLEX_FFMPEG_SOURCE_URL_PRESENT=`cat "$SCRIPT_DIR/ffmpeg-source-url"`
  echo "Present ffmpeg source obtained from $PLEX_FFMPEG_SOURCE_URL_PRESENT"
fi

# Download source archive
if [ "$PLEX_FFMPEG_SOURCE_URL" != "$PLEX_FFMPEG_SOURCE_URL_PRESENT" ]; then
  echo "Downloading latest ffmpeg source from: $PLEX_FFMPEG_SOURCE_URL"
  wget -q "$PLEX_FFMPEG_SOURCE_URL" -O "$SCRIPT_DIR/plex-media-server-ffmpeg.tar.gz"
  if [ ! -f "$SCRIPT_DIR/plex-media-server-ffmpeg.tar.gz" ]; then
    echo "Download failed!"
    exit 1
  fi
  echo "$PLEX_FFMPEG_SOURCE_URL" > "$SCRIPT_DIR/ffmpeg-source-url"
  EXTRACT_SOURCE="yes"
else
  echo "Skipping download. Latest source already downloaded."
fi

# Extract source
if [ ! -d "$SCRIPT_DIR/plex-media-server-ffmpeg" ]; then
  EXTRACT_SOURCE="yes"
fi
if [ "$EXTRACT_SOURCE" == "yes" ]; then
  echo "Extracting ffmpeg source code"
  rm -Rf "$SCRIPT_DIR/plex-media-server-ffmpeg"
  mkdir -p "$SCRIPT_DIR/plex-media-server-ffmpeg"
  cd "$SCRIPT_DIR/plex-media-server-ffmpeg"
  tar -xf "$SCRIPT_DIR/plex-media-server-ffmpeg.tar.gz" --strip-components=1
  cd "$SCRIPT_DIR"
  FFMPEG_COMPILE="yes"
fi

# Install dependencies
if [ -f "$SCRIPT_DIR/apt-packages-installed" ]; then
  APT_INSTALLED_PACKAGES=`cat "$SCRIPT_DIR/apt-packages-installed"`
  if [ "$APT_INSTALLED_PACKAGES" == "$APT_INSTALL_PACKAGES" ]; then
    INSTALL_DEPENDENCIES="no"
  fi
fi
if [ "$INSTALL_DEPENDENCIES" == "yes" ]; then
  echo "Installing missing apt packages"
  eval "sudo $APT_COMMAND $APT_INSTALL_PARAMS $APT_INSTALL_PACKAGES"
  echo "$APT_INSTALL_PACKAGES" > "$SCRIPT_DIR/apt-packages-installed"
  FFMPEG_COMPILE="yes"
fi

# Compile ffmpeg
if [ -f "$SCRIPT_DIR/ffmpeg-compiled" ]; then
  FFMPEG_CONFIGURE_FLAGS_USED=`cat "$SCRIPT_DIR/ffmpeg-compiled"`
  if [ "$FFMPEG_CONFIGURE_FLAGS_USED" != "$FFMPEG_CONFIGURE_FLAGS" ]; then
    FFMPEG_COMPILE="yes"
  fi
else
  FFMPEG_COMPILE="yes"
fi
if [ "$FFMPEG_COMPILE" == "yes" ]; then
  echo "Compiling ffmpeg"
  cd "$SCRIPT_DIR/plex-media-server-ffmpeg"
  # Apply patches
  echo "- Apply patches"
  git apply "$SCRIPT_DIR/patches/0001-avcodec-v4l2_m2m_dec-dequeue-frame-if-input-isn-t-re.patch"
  # Configure
  echo "- Configure"
  eval "./configure $FFMPEG_CONFIGURE_FLAGS"
  # Compile
  echo "- Make"
  make -j5
  cd "$SCRIPT_DIR"
  echo "$FFMPEG_CONFIGURE_FLAGS" > "$SCRIPT_DIR/ffmpeg-compiled"
else
  echo "ffmpeg already up to date. Nothing to do."
fi
