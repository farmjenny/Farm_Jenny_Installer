#!/usr/bin/python3
from farmjennycellular import farmjennycellular
import time
import RPi.GPIO as GPIO

node = farmjennycellular.FarmJennyHatLe910c(serial_port="/dev/ttyUSB2")
node.setupGPIO()
# fast blink the UserLED
node.turnOffUserLED()
GPIO.setup(node.USER_LED_N, GPIO.OUT)
p = GPIO.PWM(node.USER_LED_N,2)
p.start(50)

# if the modem is already on, try to gracefully disconnect first
if node.getModemStatus() == 0:
    print("modem already powered -- attempt disconnect first")
    try:
        node.powerDownAT()
    except:
        print("modem not responding on AT interface")
        pass

time.sleep(5)

if node.getModemStatus() == 0:
    print("modem STILL powered -- use power button")
    node.powerDownHW()

time.sleep(1)

# powerup the modem using the Farm Jenny API
node.disable()
# delay to allow USB devices to clear
time.sleep(5)
node.enable()
time.sleep(1)
node.powerUp()
time.sleep(1)
node.getIMEI()
node.getFirmwareInfo()
node.getHardwareInfo()
node.getManufacturerInfo()

# release the UserLED from PWM use (but leave all other GPIO as set)
p.stop()
GPIO.cleanup(node.USER_LED_N)