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

time.sleep(1)

if node.getModemStatus() == 0:
    print("modem STILL powered -- use power button")
    node.powerDownHW()

time.sleep(1)

# cut power and delay to allow USB devices to clear
node.disable()
time.sleep(5)
# apply power and wait for it to stabilize
node.enable()
time.sleep(1)
# the powerUp command watches for a transition on the ON/nSLEEP pin (typ 20 sec)
node.powerUp()
time.sleep(1)
# query modem info
node.getIMEI()
node.getFirmwareInfo()
node.getHardwareInfo()
node.getManufacturerInfo()

# set ON/nSLEEP (Blue LED) behavior for power monitoring (default is NW status)
node.setLedPower()

# release the UserLED from PWM use (but leave all other GPIO as set)
p.stop()
GPIO.cleanup(node.USER_LED_N)