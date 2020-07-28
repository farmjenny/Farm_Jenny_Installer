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

# if the modem is on, try to gracefully disconnect first
if node.getModemStatus() == 0:
    print("modem appears powered -- attempt disconnect first using AT interface")
    try:
        node.powerDownAT()
    except:
        print("modem not responding on AT interface")
        pass

time.sleep(5)
# plan B if that didn't work . . .
if node.getModemStatus() == 0:
    print("modem STILL powered -- use power button")
    node.powerDownHW()

time.sleep(1)
# cut power to the modem using the Farm Jenny API
node.disable()
# release the UserLED from PWM use (but leave all other GPIO as set)
p.stop()
GPIO.cleanup(node.USER_LED_N)