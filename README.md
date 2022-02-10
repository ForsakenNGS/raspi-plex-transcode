# raspi-plex-transcode
Help for manipulating the plex-media-server transcode on the raspberry pi

# Ensure hardware decoding works and your firmware is up to date

As mentioned in this forum post: https://forums.raspberrypi.com/viewtopic.php?t=262558

Hardware decoding of h264 will NOT WORK if the gpu memory is limited. I had added `gpu=16` in my `config.txt` since I run my pi headless and thought it to be a waste of ram. Setting it to `gpu=128` (the default) should be fine.

Brought to my attention by "fancybits" in the plex forums it is recommended to update the rpi kernel and firmware by running `sudo rpi-update`.

https://forums.plex.tv/t/hardware-transcoding-for-raspberry-pi-4-plex-media-server/538779/236

# Compiling plex ffmpeg with custom options

Here is what I did to compile the plex-fork of ffmpeg:

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
./configure --extra-cflags="-I/usr/local/include" --extra-ldflags="-L/usr/local/lib" --extra-libs="-lpthread -lm -latomic" --enable-gmp --enable-gpl --enable-libaom --enable-libass --enable-libdav1d --enable-libfreetype --enable-libmp3lame --enable-libopencore-amrnb --enable-libopencore-amrwb --enable-libopus --enable-librtmp --enable-libsnappy --enable-libsoxr --enable-libssh --enable-libvorbis --enable-libvpx --enable-libwebp --enable-libx264 --enable-libx265 --enable-libxml2 --enable-mmal --enable-eae --enable-nonfree --enable-version3 --target-os=linux --enable-pthreads --enable-openssl --enable-hardcoded-tables
make -j5
sudo usermod -a -G video plex
```

# Hooking into the plex transcode process

In order to use a different (hardware-)encoder I wrote a small shell script that can be put in place like this:
```
cd /home/pi/plex-media-server-ffmpeg
wget https://github.com/ForsakenNGS/raspi-plex-transcode/raw/main/ffmpeg-transcode
wget https://github.com/ForsakenNGS/raspi-plex-transcode/raw/main/ffmpeg-transcode.yaml
# Edit the configuration file to your needs
chmod +x ffmpeg-transcode
cd /usr/lib/plexmediaserver/
sudo mv 'Plex Transcoder' 'Plex Transcoder Backup'
sudo ln -s /home/pi/plex-media-server-ffmpeg/ffmpeg-transcode 'Plex Transcoder'
```

This will replace the output video encoder with the one defined in the configuration. (by default `h264_v4l2m2m`)
Also it increases the buffer size (double of default) and allows to change the segment duration of the chunks that are being rendered.

# Configuration

The wrapper `ffmpeg-transcode` will replace the plex parameters according to the configuration file `ffmpeg-transcode.yaml`. An example can be found in this repository as instructed to download above. The following options are available:

**executable** (required)

Defines the ffmpeg executable that is invoked with the altered parameters. The default is `/home/pi/plex-media-server-ffmpeg/ffmpeg`

**profiles** (required)

A list of profiles indexed by name that are being used to adjust the plex parameters. Each profile requires an `input` and `output` key which defines overrides for the default parameters. An example as included in the default configuration:
```
'profiles':
  'default':
    'input':
    'output':
      '-codec:0': 'h264_v4l2m2m'
      '-crf:0': '10'
      '-minrate:0': '1M'
      '-maxrate:0': '5M'
      '-bufsize:0': '10M'
      '-seg_duration': '2'
```
- Everything in the `input` section applies to the input stream (everything before the `-i filename` parameter).
- Everything in the `output` section applies to the output stream (everything after the `-i filename` parameter).
- Any valid ffmpeg parameter can be used.
- Repetitions of the same parameter are currently not supported.

**profile_select**

Controls when certain profiles are used. The following child-keys are available:

- **default** Defines a default profile which is used if no other rule matches. Example:
```
'profile_select':
  'default': 'default'
```

- **by_argument** Defines conditions which will trigger a certain profile to be used.
  - **argSection** One of either `input` or `output`. This will decide whether the script will check the given argument for the input or the output stream.
  - **argName** The name of the argument as supplied by plex. e.g.: `-codec:0` will check the video codec, `-i` will check the input file.
  - **type** What kind of condition will be checked. Available are:
    - **exact** Matches if the given `value` parameter matches the value of the specified argument.
    - **regex** Matches if the regex supplied within the `value` parameter matches the value of the specified argument.
    - **present** Matches if the specified argument is present.
    - **missing** Matches if the specified argument is missing.
  - **ignorecase** Currently only used for the `regex` type. Makes the regular expression case insensitive.
  - **value** The value used for matching with the `exact` and `regex` types.
  - **profile** The target profile as defined in the `profiles` section that is used if the condition matches.
  - **priority** A priority that is used when multiple conditions match. Higher is more important. If omitted the default priority of `0` is used.

Example that will match if the path or filename contain the string `anime` somewhere:
```
'profile_select':
  'by_argument':
    -
      'argSection': 'input'
      'argName': '-i'
      'type': 'regex'
      'ignorecase': true
      'value': '.*anime.*'
      'profile': 'anime'
```

# Research sources for configuration

Encoding options for `h264_v4l2m2m`: https://github.com/raspberrypi/firmware/issues/1612
