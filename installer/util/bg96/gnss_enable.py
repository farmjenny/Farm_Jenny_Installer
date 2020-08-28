#!/usr/bin/python3
from farmjennycellular import farmjennycellular
import time
import RPi.GPIO as GPIO

node = farmjennycellular.FarmJennyHatBg96(serial_port="/dev/ttyUSB2")
node.setupGPIO()
# fast blink the UserLED
node.turnOffUserLED()
GPIO.setup(node.USER_LED_N, GPIO.OUT)
p = GPIO.PWM(node.USER_LED_N,2)
p.start(50)

print("Enabling GNSS with active antenna")
node.turnOnGNSS(active_ant = True)

# release the UserLED from PWM use (but leave all other GPIO as set)
p.stop()
GPIO.cleanup(node.USER_LED_N)