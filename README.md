# Farm_Jenny_Installer
This script will install the required utilities and configure your Linux Single Board Computer (Pi) to correctly operate your Farm Jenny hardware.  It is intended for novice users.  Expert users may want to inspect the steps performed by the script and tailor the install to suit their specific requirements.

For step-by-step instructions, please follow the [Quick Start Guide for the Farm Jenny LTE Border Router HAT](https://github.com/farmjenny/FarmJenny_LTE_Border_Router_HAT/wiki/Quick-Start-Guide-for-the-Farm-Jenny-LTE-Border-Router-Hat).

## Instructions
1.  Download the installer:

    wget --backups=1 https://raw.githubusercontent.com/farmjenny/Farm_Jenny_Installer/master/installer/install.sh

2.  Change the permissions on the script to make it executable

    sudo chmod +x install.sh

3.  Run the script and follow the prompts

    sudo ./install.sh

4.  Enjoy your Farm Jenny device!
## What this script does:
1.  If your device includes a cellular modem, it installs the PPP dialer and configures the scripts (called "chatscripts") that the dialer uses to "talk" to the specific cellular modem.  If your carrier requires certain credentials to connect, these are inserted at the right places.
2.  If your device is a Raspberry Pi HAT, it installs the Farm Jenny HAT Library, which allows you to interact with the device through a simpler API.
3.  If your device can act as a Thread Border Router, it installs the OpenThread Border Router
4.  It installs a service that run at startup which configure the gpio lines needed to control the modem and use the button and LED on the HAT
5.  It installs a service that runs at powerdown or reboot to gracefully disconnect from the cellular network, helping you avoid the wrath of cellular providers who hate to see their towers ghosted by end devices.
