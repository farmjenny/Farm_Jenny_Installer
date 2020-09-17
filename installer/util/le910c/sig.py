#!/usr/bin/python3
from farmjennycellular import farmjennycellular
import time

node = farmjennycellular.FarmJennyHatLe910c(serial_port="/dev/ttyUSB2")
node.sendATComm("ATE0","OK\r\n")
node.sendATComm("AT+CSQ","OK\r\n")