#!/usr/bin/python3
from farmjennycellular import farmjennycellular
import time

# Modem configuration to connect using any technology or carrier

node = farmjennycellular.FarmJennyHatBg95(serial_port="/dev/ttyUSB2")
node.sendATComm("ATE0","OK\r\n")

# Enamble Airplane Mode
node.sendATComm("AT+CFUN=4","OK\r\n")

# Clear blacklist
node.sendATComm('AT+CRSM=214,28539,0,0,12,"FFFFFFFFFFFFFFFFFFFFFFFF"', "OK\r\n");

# Scan GSM (01), then LTE M1 (02), then NB-IoT (03) (if enabled)
node.sendATComm('AT+QCFG="nwscanseq",010203,1', "OK\r\n")

# Don't search NB-IoT
node.sendATComm('AT+QCFG="iotopmode",0,1', "OK\r\n")

# Scan GSM and LTE automatically
node.sendATComm('AT+QCFG="nwscanmode",0,1', "OK\r\n")

#Bands (Everyone)
node.sendATComm('AT+QCFG="band",F,100002000000000F0E189F,10004200000000090E189F,1', "OK\r\n")

#Service domain (CS & PS)
node.sendATComm('AT+QCFG="servicedomain",2,1', "OK\r\n")

# Turn off Airplane Mode
node.sendATComm("AT+CFUN=1","OK\r\n")

# Scan (might take a long time)
node.sendATComm("AT+COPS=?", "OK\r\n")