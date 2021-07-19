#!/usr/bin/python3
from farmjennycellular import farmjennycellular
import time
import RPi.GPIO as GPIO

node = farmjennycellular.FarmJennyHatBg95(serial_port="/dev/ttyUSB2")
node.setupGPIO()
# fast blink the UserLED
node.turnOffUserLED()
GPIO.setup(node.USER_LED_N, GPIO.OUT)
p = GPIO.PWM(node.USER_LED_N,2)
p.start(50)

print("Latitude: ", node.getLatitude())
print("Longitude: ", node.getLongitude())
print("Altitude(m): ", node.getAltitudeM())
print("Speed(MPH): ", node.getSpeedMph())
print("Speed(KPH): ", node.getSpeedKph())
print("Position Accuracy(m): ", node.getPositionAccuracyM())
print("Number of Satellites in view: ", node.getNumSatellites())
print("GNSS Date (ddmmyy UTC): ", node.getGnssDate())
print("GNSS Time (hhmmss.sss UTC): ", node.getGnssTime())

# release the UserLED from PWM use (but leave all other GPIO as set)
p.stop()
GPIO.cleanup(node.USER_LED_N)