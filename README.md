# raspi-plex-transcode
Help for manipulating the plex-media-server transcode on the raspberry pi

# Ensure hardware decoding works

As mentioned in this forum post: https://forums.raspberrypi.com/viewtopic.php?t=262558

Hardware decoding of h264 will NOT WORK if the gpu memory is limited. I had added `gpu=16` in my `config.txt` since I run my pi headless and thought it to be a waste of ram. Setting it to `gpu=128` (the default) should be fine.

# Compiling plex ffmpeg with custom options

```
cd /home/pi
cat /usr/lib/plexmediaserver/Resources/LICENSE | grep "Plex Transcoder"
# Copy the URL from the grep command and use it for the following wget
wget https://downloads.plex.tv/ffmpeg-source/plex-media-server-ffmpeg-gpl-62cc2bc17d.tar.gz
tar -xvf plex-media-server-ffmpeg-gpl-*.tar.gz
rm plex-media-server-ffmpeg-gpl-*.tar.gz
mv plex-media-server-ffmpeg-gpl-* plex-media-server-ffmpeg
cd plex-media-server-ffmpeg
sudo apt install libass-dev libaom-dev libxvidcore-dev libvorbis-dev libv4l-dev libx265-dev libx264-dev libwebp-dev libspeex-dev librtmp-dev libopus-dev libmp3lame-dev libdav1d-dev libopencore-amrnb-dev libopencore-amrwb-dev libsnappy-dev libsoxr-dev libssh-dev libxml2-dev
# If you want to apply patches or make changes to the ffmpeg source, do it here
./configure --extra-cflags="-I/usr/local/include" --extra-ldflags="-L/usr/local/lib" --extra-libs="-lpthread -lm -latomic" --enable-gmp --enable-gpl --enable-libaom --enable-libass --enable-libdav1d --enable-libfreetype --enable-libmp3lame --enable-libopencore-amrnb --enable-libopencore-amrwb --enable-libopus --enable-librtmp --enable-libsnappy --enable-libsoxr --enable-libssh --enable-libvorbis --enable-libvpx --enable-libwebp --enable-libx264 --enable-libx265 --enable-libxml2 --enable-mmal --enable-nonfree --enable-version3 --target-os=linux --enable-pthreads --enable-openssl --enable-hardcoded-tables
make -j5
```

# Hooking into the plex transcode process

In order to use a different (hardware-)encoder I wrote a small shell script that can be put in place like this:
```
cd /home/pi/plex-media-server-ffmpeg
wget https://raw.githubusercontent.com/ForsakenNGS/raspi-plex-transcode/main/ffmpeg-transcode
chmod +x ffmpeg-transcode
cd /usr/lib/plexmediaserver/
sudo mv 'Plex Transcoder' 'Plex Transcoder Backup'
sudo ln -s /home/pi/plex-media-server-ffmpeg/ffmpeg 'Plex Transcoder'
```

This will replace the output video encoder with the one defined in the script. (by default `h264_v4l2m2m`)
