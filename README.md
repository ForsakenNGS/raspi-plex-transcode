# raspi-plex-transcode
Help for manipulating the plex-media-server transcode on the raspberry pi

# Ensure hardware decoding works and your firmware is up to date

As mentioned in this forum post: https://forums.raspberrypi.com/viewtopic.php?t=262558

Hardware decoding of h264 will NOT WORK if the gpu memory is limited. I had added `gpu=16` in my `config.txt` since I run my pi headless and thought it to be a waste of ram. Setting it to `gpu=128` (the default) should be fine.

Brought to my attention by "fancybits" in the plex forums it is recommended to update the rpi kernel and firmware by running `sudo rpi-update`.

https://forums.plex.tv/t/hardware-transcoding-for-raspberry-pi-4-plex-media-server/538779/236

# TLDR Install

```
cd ~
mkdir plex-backup
cp "/usr/lib/plexmediaserver/Plex Transcoder" plex-backup/
git clone https://github.com/ForsakenNGS/raspi-plex-transcode.git
cd raspi-plex-transcode
./compile.sh
./install.sh
```

# Getting started

Log into your pi (as user `pi`) and cd into your home directory. (You can install this somewhere else if you update the configuration file accordingly)

Download this repository with git and cd into it using:
```
git clone https://github.com/ForsakenNGS/raspi-plex-transcode.git
cd raspi-plex-transcode
```

From this point you can continue with one of the three utility script:
- `compile.sh` Download the source of the plex ffmpeg-fork, install the required dependencies and compile it.
- `install.sh` Replace the original plex transcoder
- `uninstall.sh` Restore the original plex transcoder

**IMPORTANT: Backup your stuff! I'm doing my best to make the process as safe as possible, but there is always the chance that something goes wrong. Be warned!**

Most important file to backup is the original plex transcoder found by default at `/usr/lib/plexmediaserver/Plex Transcoder` e.g.:
```
mkdir ~/plex-backup
cp "/usr/lib/plexmediaserver/Plex Transcoder" ~/plex-backup/
```

# Compiling plex ffmpeg with custom options

First of all make sure you are in the directory of this projects git repository.

Now simply run `./compile.sh` which will do the following:
- Download the latest version of the plex-ffmpeg forks source code
- Extract it
- Install all required dependencies **(will ask for superuser permissions)**
- Configure and compile the ffmpeg source code

If you want to manually adjust the configure parameters you can do so in the first few lines of the `compile.sh` script.

# Installing the wrapper script

First of all make sure you are in the directory of this projects git repository.

Now simply run `./install.sh` which will do the following:
- Create a backup of the original plex transcoder script `/usr/lib/plexmediaserver/Plex Transcoder` as `/usr/lib/plexmediaserver/Plex Transcoder Backup` if not already present **(will ask for superuser permissions)**
- Remove the original plex transcoder script `/usr/lib/plexmediaserver/Plex Transcoder` **(will ask for superuser permissions)**
- Put a symlink in its place that will redirect all encoding calls to this projects wrapper script **(will ask for superuser permissions)**

# Uninstalling the wrapper script

First of all make sure you are in the directory of this projects git repository.

Now simply run `./uninstall.sh` which will do the following:
- Remove the original plex transcoder script `/usr/lib/plexmediaserver/Plex Transcoder` **(will ask for superuser permissions)**
- Move the backup of the original plex transcoder script `/usr/lib/plexmediaserver/Plex Transcoder Backup` back into its proper place at `/usr/lib/plexmediaserver/Plex Transcoder` **(will ask for superuser permissions)**

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
