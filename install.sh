# This shell script is designed to be run on a newly-imaged raspberry pi computer
# Base is: Raspberry Pi 4B with Raspberry Pi OS (Debian v11 Bullseye / systemd)

# It is designed to be run as root

# Set some global variables (always a good start!)
localUser=username
localHost=hostname

# Install some programs
echo "***************************** Programs *****************************************"
echo "Installing emacs..."
apt-get install emacs
echo "Installing screen..."
apt-get install screen
echo "Installing firefox..."
apt-get install firefox-esr

# Install media services
echo "************************** Media Services ***************************************"
echo "Installing bt-speaker..."
git clone https://github.com/shoefone/bt-speaker.git
cd bt-speaker
./install.sh
cd ..
