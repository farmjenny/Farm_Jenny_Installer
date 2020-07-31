#!/bin/bash
# This script is run by farmjenny_shutdown.service during shutdown/reboot
# It will make sure to shutdown the PPP connection and disconnect cellular

# Close PPP connection first
echo "$(date) - Disconnect PPP on shutdown/reboot" >> /home/pi/farmjenny/logs/shutdownlog.txt
sleep 2
sudo poff >> /home/pi/farmjenny/logs/shutdownlog.txt

# Then disconnect from tower and shutdown modem gracefully
echo "$(date) - Deactivating network and powering modem down -- may take 60 seconds"
sudo /usr/bin/python3 /usr/local/bin/farmjenny/modem_off.py

echo "$(date) - Cleaning up watchdog files..." >> /home/pi/farmjenny/logs/shutdownlog.txt
sudo rm /home/pi/.run-*.sh || true