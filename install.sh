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

# Install some programs
echo "***************************** Programs *****************************************"
echo "Installing emacs..."
apt-get -y install emacs
echo "Installing screen..."
apt-get -y install screen
echo "Installing firefox..."
apt-get -y install firefox-esr
echo "Installing Samba..."
apt-get -y install samba samba-common-bin
echo "Installing build software (for shairport-sync)..."
apt-get -y install --no-install-recommends \
	build-essential \
	git \
	autoconf automake \
	libtool libpopt-dev libconfig-dev libasound2-dev \
	avahi-daemon libavahi-client-dev libssl-dev libsoxr-dev \
	libplist-dev libsodium-dev libavutil-dev libavcodec-dev \
	libavformat-dev uuid-dev libgcrypt-dev xxd

# Install media services
echo "************************** Media Services ***************************************"
echo "Installing bt-speaker..."
git clone https://github.com/shoefone/bt-speaker.git
cd bt-speaker
./install.sh
cd ..

echo "Installing nqptp & shairport-sync..."
git clone https://github.com/mikebrady/nqptp.git
cd nqptp
autoreconf -fi
./configure --with-systemd-startup
make
make install
cd ..

git clone https://github.com/mikebrady/shairport-sync.git
cd shairport-sync
autoreconf -fi
./configure --sysconfdir=/etc --with-alsa \
    --with-soxr --with-avahi --with-ssl=openssl --with-systemd --with-airplay-2
make
make install
cd ..

echo "Configuring nqptp & shairport-sync..."

echo "Starting nqptp & shairport-sync..."
systemctl enable nqptp
systemctl start nqptp
systemctl enable shairport-sync
systemctl start shairport-sync
