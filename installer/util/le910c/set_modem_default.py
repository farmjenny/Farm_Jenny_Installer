#!/usr/bin/python3
from farmjennycellular import FarmJennyHatBg96
import time

# Modem configuration to connect using any technology or carrier

node = farmjennycellular.FarmJennyHatLe910c(serial_port="/dev/ttyUSB2")
# Hello!
node.sendATComm("ATE0","OK\r\n")

# Do other stuff here in the future