#!/usr/bin/python3
from farmjennycellular import farmjennycellular
import time
import RPi.GPIO as GPIO
# tests operation if the user button by illuminating the user led when pressed
node = farmjennycellular.FarmJennyHatBg95(serial_port="/dev/ttyUSB2")
# Hello!
GPIO.setwarnings(False)
node.setupGPIO()
node.turnOffUserLED()
# User button is active low
print ('Testing User Button and LED.  Green LED should light while Button is pressed.  Use <CTL>-C to exit.')
while 1:
        if node.readUserButton():
                node.turnOffUserLED()
        else:
                node.turnOnUserLED()

