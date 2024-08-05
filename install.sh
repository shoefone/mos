#!/bin/bash
# This shell script is designed to be run on a newly-imaged raspberry pi computer
# Base is: Raspberry Pi 4B with Raspberry Pi OS (Debian v11 Bullseye / systemd)

# It is designed to be run as root

# Set some global variables (always a good start!)
localUser=username
localHost=hostname

# Bring Apt up-to-date
echo "***************************** General ******************************************"
apt-get -y update
apt-get -y upgrade
echo "Installing dialog..." # GUI for shellscript
apt-get -y install dialog

# Get the userinput needed for processing
echo "***************************** Userinput ****************************************"

# Choices here should follow the terminology used by Alsa
# Common values are 'Headphones' (3.5mm jack), 'vc4hdmi0' (HDMI0 port), and 'vc4hdmi1' (HDMI1 port)

# Get shairport-sync device list with shairport-sync -h

# Get Alsa device list with $aplay -l
#readarray -t alsaDevices <<<$(aplay -l | grep -Po 'card \d: \K\w*')

# Prompt to choose music audio out
#dialog --radiolist "Audio output for music:" 0 0 0 \
# Prompt to choose video audio out
echo "////////////////// Audio Devices \\\\\\\\\\\\\\\\\\\\"
kodiAudioDevice=hw:vc4hdmi0
shairportAudioDevice=hw:Headphones
bluetoothAudioDevice=hw:Headphones
owntoneAudioDevice=hw:Headphones

echo "////////////////// Video Devices \\\\\\\\\\\\\\\\\\\\"
#kodiVideoDevice

echo "////////////////// Disks \\\\\\\\\\\\\\\\\\\\"
# Disks
# TODO : Get these from either userinput or from a scan of available devices
#        Prompt user with disks (under dev) that have actually been seen..
#        Question: How to get a list of external disks?
filesystem1=/dev/sda2
mountpoint1=/media/sda2
disktype1=ntfs

# Folders
# TODO : Add support for a list of media sources, not a single path
musicFolder=$mountpoint1/music
tvFolder=$mountpoint1/tv
movieFolder=$mountpoint1/movies

echo "////////////////// Network \\\\\\\\\\\\\\\\\\\\"
# Samba
shareName=mediaShare
sharePath=$mountpoint1

# Install some programs
echo "***************************** Programs *****************************************"
echo "Installing emacs..." # Generally useful
apt-get -y install \
	emacs firefox-esr screen gparted \
    | tee apt-get_userland.log
echo "Installing Samba..." # Media sharing (NAS functionality)
apt-get -y install \
	samba samba-common-bin \
    | tee apt-get_samba.log

echo "Installing build software (for shairport-sync & owntone)..." # autoconf ( & some others) aren't being installed. This list may be broken.
#Shairport-sync	
apt-get -y install --no-install-recommends \
    build-essential git autoconf automake libtool libpopt-dev libconfig-dev \
    libasound2-dev avahi-daemon libavahi-client-dev libssl-dev libsoxr-dev \
    libplist-dev libsodium-dev libavutil-dev libavcodec-dev libavformat-dev \
    uuid-dev libgcrypt-dev xxd \
    | tee apt-get_shairport-sync.log
	
#Owntone
apt-get -y install \
  build-essential git autotools-dev autoconf automake libtool gettext gawk \
  gperf bison flex libconfuse-dev libunistring-dev libsqlite3-dev \
  libavcodec-dev libavformat-dev libavfilter-dev libswscale-dev libavutil-dev \
  libasound2-dev libxml2-dev libgcrypt20-dev libavahi-client-dev zlib1g-dev \
  libevent-dev libplist-dev libsodium-dev libjson-c-dev libwebsockets-dev \
  libcurl4-openssl-dev libprotobuf-c-dev libpulse-dev \
  | tee apt-get_owntone.log

	
# Setup disks
echo "*************************** Setup Disks *****************************************"

mkdir $mountpoint1
# TODO : Confirm these are the appropriate permissions for a mounted drive that's being shared
chmod 2775 $mountpoint1

# Define and insert the disk entries into fstab
# TODO : List of entries, not single entry
fstab1=$filesystem1 $mountpoint1 $disktype1 defaults 0 2
echo $fstab1 | tee -a /etc/fstab


# Setup Samba
echo "***************************** NAS Setup *****************************************"
# Samba is already installed, so only some setup is needed
# Insert the share at the end of the samba configuration file

echo "" | tee -a /etc/samba/smb.conf
echo "" | tee -a /etc/samba/smb.conf
echo [$shareName] | tee -a /etc/samba/smb.conf
echo "   comment = $shareName" | tee -a /etc/samba/smb.conf
echo "   path = $sharePath" | tee -a /etc/samba/smb.conf
echo "   browsable = yes" | tee -a /etc/samba/smb.conf
echo "   read only = no" | tee -a /etc/samba/smb.conf
echo "   writable = yes" | tee -a /etc/samba/smb.conf
echo "   browsable = yes" | tee -a /etc/samba/smb.conf
echo "   public = yes" | tee -a /etc/samba/smb.conf
echo "   create mask = 0644" | tee -a /etc/samba/smb.conf
echo "   directory mask = 0755" | tee -a /etc/samba/smb.conf

echo "WARNING :: YOU WILL NEED TO SETUP A SAMBA USER IN ORDER TO ACCESS THE SHARED FOLDER!"

sudo service smbd stop
sudo service smbd start

# Install media services
echo "************************** Media Services ***************************************"
echo "-------------------------   bt-speaker    ---------------------------------------"
echo "Installing..."
git clone https://github.com/shoefone/bt-speaker.git
cd bt-speaker
./install.sh
cd ..

echo "Starting..."
systemctl start bt_speaker

echo "-------------------------   nqptp & shairport    --------------------------------"
echo "Installing nqptp & shairport-sync..."
# 20240804 - need autoconf in order to have autoreconf
apt-get install autoconf
# Thanks, Mike Brady!
git clone https://github.com/mikebrady/nqptp.git
cd nqptp
autoreconf -fi
./configure --with-systemd-startup
make
make install
cd ..

#need these as of 20240804
git clone https://github.com/mikebrady/shairport-sync.git
cd shairport-sync
autoreconf -fi
# with-soxr:
# with-avahi: avahi-based zeroconf
# with-pa: pulseaudio backend
./configure --sysconfdir=/etc --with-alsa \
    --with-soxr --with-avahi --with-ssl=openssl --with-systemd --with-airplay-2 --with-pa
make
make install
cd ..

echo "Configuring nqptp & shairport-sync..."
# Set the audio output device to the desired output devices...
shairportConfigFile=/etc/shairport-sync.conf
oldAlsaDevice=\\\/\\\/\\toutput_device\ =\ \"default\"\;
newAlsaDevice=\\toutput_device\ =\ \"$shairportAudioDevice\"\;
 sed -i "s/^$oldAlsaDevice/$newAlsaDevice/" $shairportConfigFile

echo "Starting nqptp & shairport-sync..."
systemctl enable nqptp
systemctl start nqptp
systemctl enable shairport-sync
systemctl start shairport-sync

echo "-----------------------------   owntone    -----------------------------------"
# need these as of 20240804
echo "Installing owntone..."
git clone https://github.com/owntone/owntone-server.git
cd owntone-server
autoreconf -i
#enable-install-user means that a User and Group will be added for owntone
./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --enable-install-user --with-pulseaudio
make
make install
cd ..

echo "Configuring owntone..."
# Change the directories{} entry in the library{} element to point to our music directory
# Set the audio output device to the desired output devices...
owntoneConfigFile=/etc/owntone.conf
oldOwntoneDirpath="\tdirectories = { \"/srv/music\" }";
newOwntoneDirpath="\tdirectories = { \"$musicFolder\" }";
sed -i "s/^$oldOwntoneDirpath/$newOwntoneDirpath/" $owntoneConfigFile

echo "Starting owntone..."
systemctl start owntone
