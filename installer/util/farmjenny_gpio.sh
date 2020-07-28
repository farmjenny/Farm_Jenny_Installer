#!/bin/bash

# This script is intended for installation as a service to be run at boot.  To check the status of 
# this service, use "sudo systemctl status farmjenny_gpio"
# This service exports selected gpio on the Farm Jenny HAT using legacy sysfs (file) userspace.
# Pins for the 802.15.4 radio (NCP_INT and NCPnRST) are not included as these use the newer chardev userspace.

echo "Starting Farm Jenny HAT GPIO Configuration"

# GPIO22 is nUSR_BUTTON, an ACTIVE LOW INPUT, which is pulled up in hardware
echo 22 > /sys/class/gpio/export
echo in > /sys/class/gpio/gpio22/direction

# GPIO27 is nUSR_LED, an ACTIVE LOW OUTPUT, which illuminates the Green USER LED (initialize to LED OFF)
echo 27 > /sys/class/gpio/export
echo out > /sys/class/gpio/gpio27/direction
echo 1 > /sys/class/gpio/gpio27/value

# GPIO26 is MDM_PWR, an ACTIVE HIGH OUTPUT, which ENABLES power to the cellular modem slot (initialize to modem power OFF)
echo 26 > /sys/class/gpio/export
echo out > /sys/class/gpio/gpio26/direction
echo 0 > /sys/class/gpio/gpio26/value

# GPIO23 is nMDM_STATUS, an ACTIVE LOW INPUT, which is the low side of LED4 (blue).  
# When the status LED is lit (typically indicating modem is active), this pin is low
# NOTE:  When modem is not powered (see MDM_PWR), the state of this pin is undefined.
echo 23 > /sys/class/gpio/export
echo in > /sys/class/gpio/gpio23/direction

# GPIO24 is MDM_ON_OFF, an ACTIVE HIGH OUTPUT, which is equivalent to pushing a momemtary power button on the modem.
# This pin is pulsed high for the specified minimum time to boot or shutdown the modem
# Note: MDM_PWR must be enabled before using MDM_ON_OFF
# Note: Use nMDM_STATUS to monitor status of modem (e.g., to boot, set high until nMDM_STATUS goes low, then release)
echo 24 > /sys/class/gpio/export
echo out > /sys/class/gpio/gpio24/direction
echo 0 > /sys/class/gpio/gpio24/value

echo "Done configuring Farm Jenny HAT GPIO."