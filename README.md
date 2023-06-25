# mos
Media Operating System

Started: 2023

A script to configure a stock Raspberry Pi OS machine into a audio/video mediaserver. Written to simplify / organize my efforts at getting a good setup for some Pis.



Maybe not an OS, but what's on OS, really? Could call this a distro, at least...

Based on the current version of Raspberry Pi OS, this script will install a series of programs and adjust a series of settings in order to make the Pi a functional audio/video mediaserver.

Among the functions added are:
- Airplay audio receiver (via shairport-sync)
- Bluetooth audio receiver (via bt-speaker)

To be added:
- Apple audio library (compatible with iTunes remote) (via Owntone)
- Kodi
- Local Media Filesharing
- Local HTTP interface for movies/TV
- Other...

# Hardware
All testing is being done on Raspberry Pi 4B / 4GiB machines. This will likely run on other Pi models, though limits will likely be hit on the Nano and similar-level machines.

# Todo
Maybe put this into an actual OS image. Or, a textbased GUI installer. Things of that nature.