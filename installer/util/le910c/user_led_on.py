#!/usr/bin/python3
from farmjennycellular import farmjennycellular
import time
import RPi.GPIO as GPIO

node = farmjennycellular.FarmJennyHatLe910c(serial_port="/dev/ttyUSB2")
GPIO.setwarnings(False)
node.setupGPIO()
node.turnOnUserLED()
