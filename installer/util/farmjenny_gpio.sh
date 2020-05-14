#!/bin/bash

echo "Farm Jenny GPIO Configured here"

# GPIO21 is NCP_INT, an ACTIVE HIGH INPUT, which is used by the NCP to signal the Pi's attention
echo 21 > /sys/class/gpio/export
echo in > /sys/class/gpio/gpio21/direction

# GPIO20 is NCP_nRST, an ACTIVE LOW OUTPUT, which should be initially set HIGH
echo 20 > /sys/class/gpio/export
echo out > /sys/class/gpio/gpio20/direction
echo 1 > /sys/class/gpio/gpio20/value

# GPIO22 is nUSR_BUTTON, an ACTIVE LOW INPUT, which is pulled up in hardware
echo 22 > /sys/class/gpio/export
echo in > /sys/class/gpio/gpio22/direction

# GPIO27 is nUSR_LED, an ACTIVE LOW OUTPUT, which illuminates the Green USER LED (initialize to LED OFF)
echo 27 > /sys/class/gpio/export
echo out > /sys/class/gpio/gpio27/direction
echo 1 > /sys/class/gpio/gpio27/value

# GPIO26 is PWR_OFF_P, an ACTIVE HIGH OUTPUT, which cuts power to the cellular modem slot.  This may be used to reset a stuck modem.
echo 26 > /sys/class/gpio/export
echo out > /sys/class/gpio/gpio26/direction
echo 0 > /sys/class/gpio/gpio26/value

echo "Done configuring Farm Jenny GPIO."