'''
  Farm Jenny Cellular Python Library 
  -
  Library for Farm Jenny boards, including the Farm Jenny LTE Border Router HAT. 
  -
  Author: Rob Crouthamel, Farm Jenny LLC
  -
  Adapted from SixFab https://github.com/sixfab/Sixfab_RPi_CellularIoT_App_Shield, MIT License.
'''

import time
import serial
from decimal import Decimal
import RPi.GPIO as GPIO

# global variables
TIMEOUT = 3 # seconds
ser = serial.Serial()

###########################################
### Private Methods #######################
###########################################

# Function for printing debug message 
def debug_print(message):
	print(message)

# Function for getting time as miliseconds
def millis():
	return int(time.time())

# Function for delay as miliseconds
def delay(ms):
	time.sleep(float(ms/1000.0))

###############################################
### Farm Jenny Test Class #####################
###############################################

class FarmJennyTest:
	# Initializer function
	def __init__(self):
		debug_print("Test class initialized!")
	
	def tellmeyourokay(self):
		print("Farm Jenny was here.")

###########################################################################
### Farm Jenny LTE BR HAT + Nimbelink NL-SW-LTE-QBG96 Modem Class #########
###########################################################################

class FarmJennyHatBg96:
	board = "" # shield name (LTE Border Router HAT with Quectel BG96-based Modem)
	ip_address = "" # ip address       
	domain_name = "" # domain name   
	port_number = "" # port number 
	timeout = TIMEOUT # default timeout for function and methods on this library.
	
	response = "" # variable for modem self.responses
	compose = "" # variable for command self.composes
	
	USER_BUTTON_N = 22 # Low when button is pressed.  There is a pullup on board.
	USER_LED_N = 27 # Low turns on LED2 (Green)
	MDM_PWR = 26 # High enables the power regulator for the cell modem
	MDM_STATUS_N = 23 # Low corresponds to LED4 (Blue) lit
	MDM_ON_OFF = 24 # set high momenarily, like pressing a power button
	MDM_RING = 25 # Pulses low for 120mS when URC is present.  Open drain output with 1M pullup to 3.3V in modem.
	

	# Cellular Modes
	AUTO_MODE = 0
	GSM_MODE = 1
	CATM1_MODE = 2
	CATNB1_MODE = 3

	# LTE Bands
	LTE_B1 = "1"
	LTE_B2 = "2"
	LTE_B3 = "4"
	LTE_B4 = "8"
	LTE_B5 = "10"
	LTE_B8 = "80"
	LTE_B12 = "800"
	LTE_B13 = "1000"
	LTE_B18 = "20000"
	LTE_B19 = "40000"
	LTE_B20 = "80000"
	LTE_B26 = "2000000"
	LTE_B28 = "8000000"
	LTE_B39 = "4000000000" # catm1 only
	LTE_CATM1_ANY = "400A0E189F"
	LTE_CATNB1_ANY = "A0E189F"
	LTE_NO_CHANGE = "0"

	# GSM Bands
	GSM_NO_CHANGE = "0"
	GSM_900 = "1"
	GSM_1800 = "2"
	GSM_850 = "4"
	GSM_1900 = "8"
	GSM_ANY = "F"

	SCRAMBLE_ON = "0"
	SCRAMBLE_OFF = "1"
	
	# Special Characters
	CTRL_Z = '\x1A'
	
	# Initializer function
	def __init__(self, serial_port="/dev/ttyS0", serial_baudrate=115200, board="LTE Border Router HAT with BG96", rtscts=False, dsrdtr=False):
		self.board = board
		ser.port = serial_port
		ser.baudrate = serial_baudrate
		ser.parity=serial.PARITY_NONE
		ser.stopbits=serial.STOPBITS_ONE
		ser.bytesize=serial.EIGHTBITS
		ser.rtscts=rtscts
		ser.dsrdtr=dsrdtr
		debug_print(self.board + " Class initialized!")
	
	def setupGPIO(self):
		GPIO.setwarnings(False)
		GPIO.setmode(GPIO.BCM)
		GPIO.setup(self.MDM_PWR, GPIO.OUT)
		GPIO.setup(self.USER_BUTTON_N, GPIO.IN)
		GPIO.setup(self.USER_LED_N, GPIO.OUT)
		GPIO.setup(self.MDM_STATUS_N, GPIO.IN)
		GPIO.setup(self.MDM_ON_OFF, GPIO.OUT)
		GPIO.setup(self.MDM_RING, GPIO.IN)
			
	def __del__(self): 
		# don't clear GPIO on exit or modem will turn off
		# self.clearGPIOs()
		pass
		
 	# Function for clearing global compose variable 
	def clear_compose(self):
		self.compose = ""
	
	# Function for clearing GPIO's setup
	def clearGPIOs(self):
		GPIO.cleanup()
	
	# Function for enabling power to the modem.  Note: not all models will initialize automatically.
	def enable(self):
		GPIO.output(self.MDM_PWR,1)
		debug_print("Modem power enabled!")

	# Function for cutting power to the modem.  Not advised during normal use as the modem will not disconnect properly.
	def disable(self):
		GPIO.output(self.MDM_PWR,0)
		debug_print("Modem power disabled!")

	# Function for powering up or down the modem using the on-off key
	def powerUp(self):
		GPIO.output(self.MDM_ON_OFF,1)
		while self.getModemStatus():  # loop until modem status goes low, indicating it has booted (LED 4, blue, lit)
			pass
		debug_print("modem powered up!")
		GPIO.output(self.MDM_ON_OFF,0)
	
	# Function for getting modem power status
	def getModemStatus(self):
		# Modem status pin state is undefined if modem VCC is not powered.  Return 1 if modem is disabled.
		if not GPIO.input(self.MDM_PWR):
			return 1
		else:
			return GPIO.input(self.MDM_STATUS_N)

	# Function for getting modem response
	def getResponse(self, desired_response):
		if (ser.isOpen() == False):
			ser.open()
		while 1:	
			self.response =""
			while(ser.inWaiting()):
				self.response += ser.read(ser.inWaiting()).decode('utf-8', errors='ignore')
			if(self.response.find(desired_response) != -1):
				debug_print(self.response)
				break
	
	# Function for sending data to module
	def sendDataCommOnce(self, command):
		if (ser.isOpen() == False):
			ser.open()		
		self.compose = "" 
		self.compose = str(command)
		ser.reset_input_buffer()
		ser.write(self.compose.encode())
		debug_print(self.compose)

	# Function for sending at comamand to module
	def sendATCommOnce(self, command):
		if (ser.isOpen() == False):
			ser.open()		
		self.compose = ""
		self.compose = str(command) + "\r"
		ser.reset_input_buffer()
		ser.write(self.compose.encode())
		#debug_print(self.compose)
		
	# Function for sending data to AT.
	def sendDataComm(self, command, desired_response, timeout = None):
		if timeout is None:
			timeout = self.timeout
		self.sendDataCommOnce(command)
		timer = millis()
		while 1:
			if(millis() - timer > timeout): 
				self.sendDataCommOnce(command)
				timer = millis()
			self.response = ""
			while(ser.inWaiting()):
				self.response += ser.read(ser.inWaiting()).decode('utf-8', errors='ignore')
			if(self.response.find(desired_response) != -1):
				debug_print(self.response)
				break

	# Function for sending at command to AT.
	def sendATComm(self, command, desired_response, timeout = None):
		if timeout is None:
			timeout = self.timeout
		self.sendATCommOnce(command)
		#f_debug = False
		timer = millis()
		while 1:
			if( millis() - timer > timeout): 
				self.sendATCommOnce(command)
				timer = millis()
				#f_debug = False
			self.response =""
			while(ser.inWaiting()):
				try: 
					self.response += ser.read(ser.inWaiting()).decode('utf-8', errors='ignore')
					delay(100)
				except Exception as e:
					debug_print(e)
				# debug_print(self.response)	
			if(self.response.find(desired_response) != -1):
				debug_print(self.response)
				return self.response # returns the response of the command as string.

	# Function for saving conf. and reset the modem
	def resetModule(self):
		self.saveConfigurations()
		delay(200)
		self.disable()
		delay(200)
		self.enable()

	# Function for save configurations that be done in current session. 
	def saveConfigurations(self):
		self.sendATComm("AT&W","OK\r\n")

	# Function for getting IMEI number
	def getIMEI(self):
		return self.sendATComm("AT+CGSN","OK\r\n")	# Identical command: AT+GSN

	# Function for getting firmware info
	def getFirmwareInfo(self):
		return self.sendATComm("AT+CGMR","OK\r\n")	# Identical command: AT+GMR

	# Function for getting hardware info
	def getHardwareInfo(self):
		return self.sendATComm("AT+CGMM","OK\r\n")	# Identical command: AT+GMM

	# Function returning Manufacturer Identification 
	def getManufacturerInfo(self):
		return self.sendATComm("AT+CGMI","OK\r\n")	# Identical command: AT+GMI

	# Function for setting GSM Band
	def setGSMBand(self, gsm_band):
		self.compose = "AT+QCFG=\"band\","
		self.compose += str(gsm_band)
		self.compose += ","
		self.compose += str(self.LTE_NO_CHANGE)
		self.compose += ","
		self.compose += str(self.LTE_NO_CHANGE)

		self.sendATComm(self.compose,"OK\r\n")
		self.clear_compose()

	# Function for setting Cat.M1 Band
	def setCATM1Band(self, catm1_band):
		self.compose = "AT+QCFG=\"band\","
		self.compose += str(self.GSM_NO_CHANGE)
		self.compose += ","
		self.compose += str(catm1_band)
		self.compose += ","
		self.compose += str(self.LTE_NO_CHANGE)

		self.sendATComm(self.compose,"OK\r\n")
		self.clear_compose()

	# Function for setting NB-IoT Band
	def setNBIoTBand(self, nbiot_band):
		self.compose = "AT+QCFG=\"band\","
		self.compose += str(self.GSM_NO_CHANGE)
		self.compose += ","
		self.compose += str(self.LTE_NO_CHANGE)
		self.compose += ","
		self.compose += str(nbiot_band)

		self.sendATComm(self.compose,"OK\r\n")
		self.clear_compose()

	# Function for getting current band settings
	def getBandConfiguration(self):
		return self.sendATComm("AT+QCFG=\"band\"","OK\r\n")

	# Function for setting scramble feature configuration 
	def setScrambleConf(self, scramble):
		self.compose = "AT+QCFG=\"nbsibscramble\","
		self.compose += scramble

		self.sendATComm(self.compose,"OK\r\n")
		self.clear_compose()

	# Function for setting running mode.
	def setMode(self, mode):
		if(mode == self.AUTO_MODE):
			self.sendATComm("AT+QCFG=\"nwscanseq\",00,1","OK\r\n")
			self.sendATComm("AT+QCFG=\"nwscanmode\",0,1","OK\r\n")
			self.sendATComm("AT+QCFG=\"iotopmode\",2,1","OK\r\n")
			debug_print("Modem configuration : AUTO_MODE")
			debug_print("*Priority Table (Cat.M1 -> Cat.NB1 -> GSM)")
		elif(mode == self.GSM_MODE):
			self.sendATComm("AT+QCFG=\"nwscanseq\",01,1","OK\r\n")
			self.sendATComm("AT+QCFG=\"nwscanmode\",1,1","OK\r\n")
			self.sendATComm("AT+QCFG=\"iotopmode\",2,1","OK\r\n")
			debug_print("Modem configuration : GSM_MODE")
		elif(mode == self.CATM1_MODE):
			self.sendATComm("AT+QCFG=\"nwscanseq\",02,1","OK\r\n")
			self.sendATComm("AT+QCFG=\"nwscanmode\",3,1","OK\r\n")
			self.sendATComm("AT+QCFG=\"iotopmode\",0,1","OK\r\n")
			debug_print("Modem configuration : CATM1_MODE")
		elif(mode == self.CATNB1_MODE):
			self.sendATComm("AT+QCFG=\"nwscanseq\",03,1","OK\r\n")
			self.sendATComm("AT+QCFG=\"nwscanmode\",3,1","OK\r\n")
			self.sendATComm("AT+QCFG=\"iotopmode\",1,1","OK\r\n")
			debug_print("Modem configuration : CATNB1_MODE ( NB-IoT )")

	# Function for getting self.ip_address
	def getIPAddress(self):
		return self.ip_address

	# Function for setting self.ip_address
	def setIPAddress(self, ip):
		self.ip_address = ip

	# Function for getting self.domain_name
	def getDomainName(self):
		return self.domain_name

	# Function for setting domain name
	def setDomainName(self, domain):
		self.domain_name = domain

	# Function for getting port
	def getPort(self):
		return self.port_number

	# Function for setting port
	def setPort(self, port):
		self.port_number = port

	# Function for getting timout in ms
	def getTimeout(self):
		return self.timeout

	# Function for setting timeout in ms    
	def setTimeout(self, new_timeout):
		self.timeout = new_timeout

	#******************************************************************************************
	#*** SIM Related Functions ****************************************************************
	#****************************************************************************************** 

	# Function returns Mobile Subscriber Identity(IMSI)
	def getIMSI(self):
		return self.sendATComm("AT+CIMI","OK\r\n")

	# Functions returns Integrated Circuit Card Identifier(ICCID) number of the SIM
	def getICCID(self):
		return self.sendATComm("AT+QCCID","OK\r\n")

	#******************************************************************************************
	#*** Network Service Functions ************************************************************
	#****************************************************************************************** 

	# Fuction for getting signal quality
	def getSignalQuality(self):
		return self.sendATComm("AT+CSQ","OK\r\n")

	# Function for getting network information
	def getQueryNetworkInfo(self):
		return self.sendATComm("AT+QNWINFO","OK\r\n")

	# Function for connecting to base station of operator
	def connectToOperator(self):
		debug_print("Trying to connect base station of operator...")
		self.sendATComm("AT+CGATT?","+CGATT: 1\r\n")
		self.getSignalQuality()

	# Fuction to check the Network Registration Status
	def getNetworkRegStatus(self):
		return self.sendATComm("AT+CREG?","OK\r\n")
	
	# Function to check the Operator
	def getOperator(self):
		return self.sendATComm("AT+COPS?","OK\r\n")


	#******************************************************************************************
	#*** SMS Functions ************************************************************************
	#******************************************************************************************
	
	# Function for sending SMS
	def sendSMS(self, number, text):
		self.sendATComm("AT+CMGF=1","OK\r\n") # text mode	
		delay(500)
		
		self.compose = "AT+CMGS=\""
		self.compose += str(number)
		self.compose += "\""

		self.sendATComm(self.compose,">")
		delay(1000)
		self.clear_compose()
		delay(1000)
		self.sendATCommOnce(text)
		self.sendATComm(self.CTRL_Z,"OK",8) # with 8 seconds timeout
		
	#******************************************************************************************
	#*** BG96 GNSS Functions ******************************************************************
	#******************************************************************************************

	# Function for turning on GNSS (and enable active antenna if so equipped)
	def turnOnGNSS(self,active_ant = False):
		if(active_ant == True):
			#apply DC power to antenna
			self.sendATComm("ATE0","OK\r\n")
			self.sendATComm("AT+QCFG=\"gpio\",1,64,1,0,0,1","OK\r\n")
			self.sendATComm("AT+QCFG=\"gpio\",3,64,1,1","OK\r\n")

		# Note: AT+QGPS=1 fails if GPS is already enabled, so to be safe, always issue QGSPEND first
		self.sendATComm("AT+QGPSEND","OK\r\n")
		delay(1000)
		self.sendATComm("AT+QGPS=1","OK\r\n")

	# Function for turning off GNSS (and turn off active antenna if so equipped)
	def turnOffGNSS(self,active_ant = False):
		if(active_ant == True):
			#remove DC power to antenna to save power
			self.sendATComm("ATE0","OK\r\n")
			self.sendATComm("AT+QCFG=\"gpio\",1,64,1,0,0,1","OK\r\n")
			self.sendATComm("AT+QCFG=\"gpio\",3,64,0,1","OK\r\n")

		self.sendATComm("AT+QGPSEND","OK\r\n")		

	# Function for getting latitude
	def getLatitude(self):
		self.sendATComm("ATE0","OK\r\n")
		self.sendATCommOnce("AT+QGPSLOC=2")
		#timer = millis()
		while 1:
			self.response = ""
			while(ser.inWaiting()):
				self.response += ser.readline().decode('utf-8')
				if( self.response.find("QGPSLOC") != -1 and self.response.find("OK") != -1 ):
					self.response = self.response.split(",")
					ser.close()
					return Decimal(self.response[1])
				if(self.response.find("\r\n") != -1 and self.response.find("ERROR") != -1 ):
					debug_print(self.response)
					ser.close()
					return 0
	
	# Function for getting longitude		
	def getLongitude(self):
		self.sendATComm("ATE0","OK\r\n")
		self.sendATCommOnce("AT+QGPSLOC=2")
		#timer = millis()
		while 1:
			self.response = ""
			while(ser.inWaiting()):
				self.response += ser.readline().decode('utf-8')
				if( self.response.find("QGPSLOC") != -1 and self.response.find("OK") != -1 ):
					self.response = self.response.split(",")
					ser.close()
					return Decimal(self.response[2])
				if(self.response.find("\r\n") != -1 and self.response.find("ERROR") != -1 ):
					debug_print(self.response)
					ser.close()
					return 0
	
	# Function for getting speed in MPH			
	def getSpeedMph(self):
		self.sendATComm("ATE0","OK\r\n")
		self.sendATCommOnce("AT+QGPSLOC=2")
		#timer = millis()
		while 1:
			self.response = ""
			while(ser.inWaiting()):
				self.response += ser.readline().decode('utf-8')
				if( self.response.find("QGPSLOC") != -1 and self.response.find("OK") != -1 ):
					self.response = self.response.split(",")
					ser.close()
					return round(Decimal(self.response[7])/Decimal('1.609344'), 1)
				if(self.response.find("\r\n") != -1 and self.response.find("ERROR") != -1 ):
					debug_print(self.response)
					ser.close()
					return 0
	
	# Function for getting speed in KPH			
	def getSpeedKph(self):
		self.sendATComm("ATE0","OK\r\n")
		self.sendATCommOnce("AT+QGPSLOC=2")
		#timer = millis()
		while 1:
			self.response = ""
			while(ser.inWaiting()):
				self.response += ser.readline().decode('utf-8')
				if( self.response.find("QGPSLOC") != -1 and self.response.find("OK") != -1 ):
					self.response = self.response.split(",")
					ser.close()
					return Decimal(self.response[7])
				if(self.response.find("\r\n") != -1 and self.response.find("ERROR") != -1 ):
					debug_print(self.response)
					ser.close()
					return 0

	# Function for getting fixed location 
	def getFixedLocation(self):
		return self.sendATComm("AT+QGPSLOC?","+QGPSLOC:")

	#******************************************************************************************
	#*** TCP & UDP Protocols Functions ********************************************************
	#******************************************************************************************

	# Function for configurating and activating TCP context 
	def activateContext(self):
	  self.sendATComm("AT+QICSGP=1","OK\r\n") 
	  delay(1000)
	  self.sendATComm("AT+QIACT=1","\r\n")

	# Function for deactivating TCP context 
	def deactivateContext(self):
	  self.sendATComm("AT+QIDEACT=1","\r\n")

	# Function for connecting to server via TCP
	# just buffer access mode is supported for now.
	def connectToServerTCP(self):
		self.compose = "AT+QIOPEN=1,1"
		self.compose += ",\"TCP\",\""
		self.compose += str(self.ip_address)
		self.compose += "\","
		self.compose += str(self.port_number)
		self.compose += ",0,0"
		self.sendATComm(self.compose,"OK\r\n")
		self.clear_compose()
		self.sendATComm("AT+QISTATE=0,1","OK\r\n")

	# Fuction for sending data via tcp.
	# just buffer access mode is supported for now.
	def sendDataTCP(self, data):
		self.compose = "AT+QISEND=1,"
		self.compose += str(len(data))
		self.sendATComm(self.compose,">")
		self.sendATComm(data,"SEND OK")
		self.clear_compose()
		
	# Function for sending data to IFTTT	
	def sendDataIFTTT(self, eventName, key, data):
		self.compose = "AT+QHTTPCFG=\"contextid\",1"
		self.sendATComm(self.compose,"OK")
		self.clear_compose()
		self.compose = "AT+QHTTPCFG=\"requestheader\",1"
		self.sendATComm(self.compose,"OK")
		self.clear_compose()
		self.compose = "AT+QHTTPCFG=\"self.responseheader\",1"
		self.sendATComm(self.compose,"OK")
		self.clear_compose()
		url = str("https://maker.ifttt.com/trigger/" + eventName + "/with/key/"+ key)
		self.compose = "AT+QHTTPURL="
		self.compose += str(len(url))
		self.compose += ",80"
		self.setTimeout(20)
		self.sendATComm(self.compose,"CONNECT")
		self.clear_compose()
		self.sendDataComm(url,"OK")
		payload = "POST /trigger/" + eventName + "/with/key/"+ key +" HTTP/1.1\r\nHost: maker.ifttt.com\r\nContent-Type: application/json\r\nContent-Length: "+str(len(data))+"\r\n\r\n"
		payload += data
		self.compose = "AT+QHTTPPOST="
		self.compose += str(len(payload))
		self.compose += ",60,60"
		self.sendATComm(self.compose,"CONNECT")
		self.clear_compose()
		self.sendDataComm(payload,"OK")
		delay(5000)
		self.sendATComm("AT+QHTTPREAD=80","+QHTTPREAD: 0")
	
	# Function for sending data to Thingspeak
	def sendDataThingspeak(self, key, data):
		self.compose = "AT+QHTTPCFG=\"contextid\",1"
		self.sendATComm(self.compose,"OK")
		self.clear_compose()
		self.compose = "AT+QHTTPCFG=\"requestheader\",0"
		self.sendATComm(self.compose,"OK")
		self.clear_compose()
		url = str("https://api.thingspeak.com/update?api_key=" + key + "&"+ data)
		self.compose = "AT+QHTTPURL="
		self.compose += str(len(url))
		self.compose += ",80"
		self.setTimeout(20)
		self.sendATComm(self.compose,"CONNECT")
		self.clear_compose()
		self.sendDataComm(url,"OK")
		delay(3000)
		self.sendATComm("AT+QHTTPGET=80","+QHTTPGET")

	# Function for connecting to server via UDP
	def startUDPService(self):
		port = "3005"
		self.compose = "AT+QIOPEN=1,1,\"UDP SERVICE\",\""
		self.compose += str(self.ip_address)
		self.compose += "\",0,"
		self.compose += str(port)
		self.compose += ",0"
		self.sendATComm(self.compose,"OK\r\n")
		self.clear_compose()
		self.sendATComm("AT+QISTATE=0,1","\r\n")

	# Fuction for sending data via udp.
	def sendDataUDP(self, data):
		self.compose = "AT+QISEND=1,"
		self.compose += str(len(data))
		self.compose += ",\""
		self.compose += str(self.ip_address)
		self.compose += "\","
		self.compose += str(self.port_number)
		self.sendATComm(self.compose,">")
		self.clear_compose()
		self.sendATComm(data,"SEND OK")

	# Function for closing server connection
	def closeConnection(self):
		self.sendATComm("AT+QICLOSE=1","\r\n")
		
	# Function for disconnecting (Deregistering) from the cell network and powering down gracefully using AT commands (preferred)
	def powerDownAT(self):
		self.sendATComm("ATE0","OK\r\n")
		# Deregister from the network (within 60 seconds and power down)
		self.sendATComm("AT+QPOWD=1","POWERED DOWN\r\n", 60000)

	# Function for disconnecting (Deregistering) from the cell network and powering down gracefully using On/off Line (Hardware)
	def powerDownHW(self):
		# pulse ON-OFF line for at least 650 mS to initiate a powerdown
		GPIO.output(self.MDM_ON_OFF,1)
		delay(800)
		GPIO.output(self.MDM_ON_OFF,0)
		debug_print("power down requested.  NOTE: This can take up to 60 seconds to complete.")
		i = 0
		while i < 60: 
			if self.getModemStatus():
				debug_print("modem still on")
				i += 1
			else:
				debug_print("modem powered down")
				return
		debug_print("power down timed out.  Modem may be stuck.")

	#******************************************************************************************
	#*** HAT Peripheral Functions *************************************************************
	#******************************************************************************************

	# Function for reading user button (active low)
	def readUserButton(self):
		return GPIO.input(self.USER_BUTTON_N)

	# Function for turning on user LED
	def turnOnUserLED(self):
		GPIO.output(self.USER_LED_N, 0)
	
	# Function for turning off user LED
	def turnOffUserLED(self):
		GPIO.output(self.USER_LED_N, 1)
	
###########################################################################
### Farm Jenny LTE BR HAT + Nimbelink NL-SW-LTE-TC4NAG Modem Class ########
###########################################################################

class FarmJennyHatLe910c:
	board = "" # shield name (LTE Border Router HAT with Quectel BG96-based Modem)
	ip_address = "" # ip address       
	domain_name = "" # domain name   
	port_number = "" # port number 
	timeout = TIMEOUT # default timeout for function and methods on this library.
	
	response = "" # variable for modem self.responses
	compose = "" # variable for command self.composes
	
	USER_BUTTON_N = 22 # Low when button is pressed.  There is a pullup on board.
	USER_LED_N = 27 # Low turns on LED2 (Green)
	MDM_PWR = 26 # High enables the power regulator for the cell modem
	MDM_STATUS_N = 23 # Low corresponds to LED4 (Blue) lit
	MDM_ON_OFF = 24 # set high momenarily, like pressing a power button
	MDM_RING = 25 # Pulses low for 120mS when URC is present.  Open drain output with 1M pullup to 3.3V in modem.
	
	# Special Characters
	CTRL_Z = '\x1A'
	
	# Initializer function
	def __init__(self, serial_port="/dev/ttyS0", serial_baudrate=115200, board="LTE Border Router HAT with LE910C", rtscts=False, dsrdtr=False):
		self.board = board
		ser.port = serial_port
		ser.baudrate = serial_baudrate
		ser.parity=serial.PARITY_NONE
		ser.stopbits=serial.STOPBITS_ONE
		ser.bytesize=serial.EIGHTBITS
		ser.rtscts=rtscts
		ser.dsrdtr=dsrdtr
		debug_print(self.board + " Class initialized!")
	
	def setupGPIO(self):
		GPIO.setwarnings(False)
		GPIO.setmode(GPIO.BCM)
		GPIO.setup(self.MDM_PWR, GPIO.OUT)
		GPIO.setup(self.USER_BUTTON_N, GPIO.IN)
		GPIO.setup(self.USER_LED_N, GPIO.OUT)
		GPIO.setup(self.MDM_STATUS_N, GPIO.IN)
		GPIO.setup(self.MDM_ON_OFF, GPIO.OUT)
		GPIO.setup(self.MDM_RING, GPIO.IN)
			
	def __del__(self): 
		# don't clear GPIO on exit or modem will turn off
		# self.clearGPIOs()
		pass
		
 	# Function for clearing global compose variable 
	def clear_compose(self):
		self.compose = ""
	
	# Function for clearing GPIO's setup
	def clearGPIOs(self):
		GPIO.cleanup()
	
	# Function for enabling power to the modem.  Note: not all models will initialize automatically.
	def enable(self):
		GPIO.output(self.MDM_PWR,1)
		debug_print("Modem power enabled!")

	# Function for cutting power to the modem.  Not advised during normal use as the modem will not disconnect properly.
	def disable(self):
		GPIO.output(self.MDM_PWR,0)
		debug_print("Modem power disabled!")

	# Function for powering up or down the modem using the on-off key
	def powerUp(self):
		GPIO.output(self.MDM_ON_OFF,1)
		while self.getModemStatus():  # loop until modem status goes low, indicating it has booted (LED 4, blue, lit)
			pass
		debug_print("modem powered up!")
		GPIO.output(self.MDM_ON_OFF,0)
	
	# Function for getting modem power status
	def getModemStatus(self):
		# Modem status pin state is undefined if modem VCC is not powered.  Return 1 if modem is disabled.
		if not GPIO.input(self.MDM_PWR):
			return 1
		else:
			return GPIO.input(self.MDM_STATUS_N)

	# Function for getting modem response
	def getResponse(self, desired_response):
		if (ser.isOpen() == False):
			ser.open()
		while 1:	
			self.response =""
			while(ser.inWaiting()):
				self.response += ser.read(ser.inWaiting()).decode('utf-8', errors='ignore')
			if(self.response.find(desired_response) != -1):
				debug_print(self.response)
				break
	
	# Function for sending data to module
	def sendDataCommOnce(self, command):
		if (ser.isOpen() == False):
			ser.open()		
		self.compose = "" 
		self.compose = str(command)
		ser.reset_input_buffer()
		ser.write(self.compose.encode())
		debug_print(self.compose)

	# Function for sending at comamand to module
	def sendATCommOnce(self, command):
		if (ser.isOpen() == False):
			ser.open()		
		self.compose = ""
		self.compose = str(command) + "\r"
		ser.reset_input_buffer()
		ser.write(self.compose.encode())
		#debug_print(self.compose)
		
	# Function for sending data to AT.
	def sendDataComm(self, command, desired_response, timeout = None):
		if timeout is None:
			timeout = self.timeout
		self.sendDataCommOnce(command)
		timer = millis()
		while 1:
			if(millis() - timer > timeout): 
				self.sendDataCommOnce(command)
				timer = millis()
			self.response = ""
			while(ser.inWaiting()):
				self.response += ser.read(ser.inWaiting()).decode('utf-8', errors='ignore')
			if(self.response.find(desired_response) != -1):
				debug_print(self.response)
				break

	# Function for sending at command to AT.
	def sendATComm(self, command, desired_response, timeout = None):
		if timeout is None:
			timeout = self.timeout
		self.sendATCommOnce(command)
		#f_debug = False
		timer = millis()
		while 1:
			if( millis() - timer > timeout): 
				self.sendATCommOnce(command)
				timer = millis()
				#f_debug = False
			self.response =""
			while(ser.inWaiting()):
				try: 
					self.response += ser.read(ser.inWaiting()).decode('utf-8', errors='ignore')
					delay(100)
				except Exception as e:
					debug_print(e)
				# debug_print(self.response)	
			if(self.response.find(desired_response) != -1):
				debug_print(self.response)
				return self.response # returns the response of the command as string.

	# Function for saving conf. and reset the modem
	def resetModule(self):
		self.saveConfigurations()
		delay(200)
		self.disable()
		delay(200)
		self.enable()

	# Function for save configurations that be done in current session. 
	def saveConfigurations(self):
		self.sendATComm("AT&W","OK\r\n")

	# Function for getting IMEI number
	def getIMEI(self):
		return self.sendATComm("AT+CGSN","OK\r\n")	# Identical command: AT+GSN

	# Function for getting firmware info
	def getFirmwareInfo(self):
		return self.sendATComm("AT+CGMR","OK\r\n")	# Identical command: AT+GMR

	# Function for getting hardware info
	def getHardwareInfo(self):
		return self.sendATComm("AT+CGMM","OK\r\n")	# Identical command: AT+GMM

	# Function returning Manufacturer Identification 
	def getManufacturerInfo(self):
		return self.sendATComm("AT+CGMI","OK\r\n")	# Identical command: AT+GMI

	# Function for getting self.ip_address
	def getIPAddress(self):
		return self.ip_address

	# Function for setting self.ip_address
	def setIPAddress(self, ip):
		self.ip_address = ip

	# Function for getting self.domain_name
	def getDomainName(self):
		return self.domain_name

	# Function for setting domain name
	def setDomainName(self, domain):
		self.domain_name = domain

	# Function for getting port
	def getPort(self):
		return self.port_number

	# Function for setting port
	def setPort(self, port):
		self.port_number = port

	# Function for getting timout in ms
	def getTimeout(self):
		return self.timeout

	# Function for setting timeout in ms    
	def setTimeout(self, new_timeout):
		self.timeout = new_timeout

	#******************************************************************************************
	#*** SIM Related Functions ****************************************************************
	#****************************************************************************************** 

	# Function returns Mobile Subscriber Identity(IMSI)
	def getIMSI(self):
		return self.sendATComm("AT+CIMI","OK\r\n")

	# Functions returns Integrated Circuit Card Identifier(ICCID) number of the SIM
	def getICCID(self):
		return self.sendATComm("AT+ICCID","OK\r\n")

	#******************************************************************************************
	#*** Network Service Functions ************************************************************
	#****************************************************************************************** 

	# Fuction for getting signal quality
	def getSignalQuality(self):
		return self.sendATComm("AT+CSQ","OK\r\n")

	# Function for getting network information
	def getQueryNetworkInfo(self):
		return self.sendATComm("AT#SERVINFO","OK\r\n")

	# Function for connecting to base station of operator
	def connectToOperator(self):
		debug_print("Trying to connect base station of operator...")
		self.sendATComm("AT+CGATT?","+CGATT: 1\r\n")
		self.getSignalQuality()

	# Fuction to check the Network Registration Status
	def getNetworkRegStatus(self):
		return self.sendATComm("AT+CREG?","OK\r\n")
	
	# Function to check the Operator
	def getOperator(self):
		return self.sendATComm("AT+COPS?","OK\r\n")


	#******************************************************************************************
	#*** SMS Functions ************************************************************************
	#******************************************************************************************
	
	# Function for sending SMS
	def sendSMS(self, number, text):
		self.sendATComm("AT+CMGF=1","OK\r\n") # text mode	
		delay(500)
		
		self.compose = "AT+CMGS=\""
		self.compose += str(number)
		self.compose += "\""

		self.sendATComm(self.compose,">")
		delay(1000)
		self.clear_compose()
		delay(1000)
		self.sendATCommOnce(text)
		self.sendATComm(self.CTRL_Z,"OK",8) # with 8 seconds timeout
		
	#******************************************************************************************
	#*** GNSS Functions ***********************************************************************
	#******************************************************************************************

	# Function for turning on GNSS
	def turnOnGNSS(self):
		#powerup GNSS subsystem
		self.sendATComm("AT$GPSP=1","OK\r\n")
		#enable location services
		self.sendATComm("AT$LOCATION=1","OK\r\n")

	# Function for turning of GNSS
	def turnOffGNSS(self):
		#disable location services
		self.sendATComm("AT$LOCATION=0","OK\r\n")
		#shutdown GNSS subsystem
		self.sendATComm("AT$GPSP=0","OK\r\n")
		
	
	# Function for getting latitude
	def getLatitude(self):
		self.sendATComm("ATE0","OK\r\n")
		self.sendATCommOnce("AT$GETLOCATION")
		#timer = millis()
		while 1:
			self.response = ""
			while(ser.inWaiting()):
				self.response += ser.readline().decode('utf-8')
				if( self.response.find("OK") != -1 ):
					self.response = self.response.split(",")
					ser.close()
					return Decimal(self.response[2])
				if(self.response.find("\r\n") != -1 and self.response.find("ERROR") != -1 ):
					debug_print(self.response)
					ser.close()
					return 0
	
	# Function for getting longitude		
	def getLongitude(self):
		self.sendATComm("ATE0","OK\r\n")
		self.sendATCommOnce("AT$GETLOCATION")
		#timer = millis()
		while 1:
			self.response = ""
			while(ser.inWaiting()):
				self.response += ser.readline().decode('utf-8')
				if( self.response.find("OK") != -1 ):
					self.response = self.response.split(",")
					ser.close()
					return Decimal(self.response[3])
				if(self.response.find("\r\n") != -1 and self.response.find("ERROR") != -1 ):
					debug_print(self.response)
					ser.close()
					return 0
	
	# Function for getting speed in MPH			
	def getSpeedMph(self):
		self.sendATComm("ATE0","OK\r\n")
		self.sendATCommOnce("AT$GETLOCATION")
		#timer = millis()
		while 1:
			self.response = ""
			while(ser.inWaiting()):
				self.response += ser.readline().decode('utf-8')
				if( self.response.find("OK") != -1 ):
					self.response = self.response.split(",")
					ser.close()
					#speed returned is meters per second, multiply by 2.237 for mph
					return round(Decimal(self.response[6])*Decimal('2.237'), 1)
				if(self.response.find("\r\n") != -1 and self.response.find("ERROR") != -1 ):
					debug_print(self.response)
					ser.close()
					return 0
	
	# Function for getting speed in KPH			
	def getSpeedKph(self):
		self.sendATComm("ATE0","OK\r\n")
		self.sendATCommOnce("AT$GETLOCATION")
		#timer = millis()
		while 1:
			self.response = ""
			while(ser.inWaiting()):
				self.response += ser.readline().decode('utf-8')
				if( self.response.find("OK") != -1 ):
					self.response = self.response.split(",")
					ser.close()
					#speed is meters per second, multiply by 3.6 for kph
					return round(Decimal(self.response[6])*Decimal('3.6'), 1)
				if(self.response.find("\r\n") != -1 and self.response.find("ERROR") != -1 ):
					debug_print(self.response)
					ser.close()
					return 0

	# Function for getting fixed location 
	def getFixedLocation(self):
		return self.sendATComm("AT$GETLOCATION","+QGPSLOC:")

	#******************************************************************************************
	#*** TCP & UDP Protocols Functions ********************************************************
	#******************************************************************************************

	# Function for configurating and activating TCP context 
	def activateContext(self):
	  print("ERROR: Function not implemented.")

	# Function for deactivating TCP context 
	def deactivateContext(self):
	  print("ERROR: Function not implemented.")

	# Function for connecting to server via TCP
	# just buffer access mode is supported for now.
	def connectToServerTCP(self):
		print("ERROR: Function not implemented.")

	# Fuction for sending data via tcp.
	# just buffer access mode is supported for now.
	def sendDataTCP(self, data):
		print("ERROR: Function not implemented.")
		
	# Function for sending data to IFTTT	
	def sendDataIFTTT(self, eventName, key, data):
		print("ERROR: Function not implemented.")
	
	# Function for sending data to Thingspeak
	def sendDataThingspeak(self, key, data):
		print("ERROR: Function not implemented.")

	# Function for connecting to server via UDP
	def startUDPService(self):
		print("ERROR: Function not implemented.")

	# Fuction for sending data via udp.
	def sendDataUDP(self, data):
		print("ERROR: Function not implemented.")

	# Function for closing server connection
	def closeConnection(self):
		print("ERROR: Function not implemented.")
		
	# Function for disconnecting (Deregistering) from the cell network and powering down gracefully using AT commands (preferred)
	def powerDownAT(self):
		self.sendATComm("ATE0","OK\r\n")
		# Deregister from the network (within 25 seconds according to LE910 datasheet) and power down
		self.sendATComm("AT#SHDN","OK\r\n", 30000)

	# Function for disconnecting (Deregistering) from the cell network and powering down gracefully using On/off Line (Hardware)
	def powerDownHW(self):
		# pulse ON-OFF line for at least 2500mS to initiate a powerdown (according to Nimbelink datasheet)
		GPIO.output(self.MDM_ON_OFF,1)
		delay(2600)
		GPIO.output(self.MDM_ON_OFF,0)
		debug_print("power down requested.  NOTE: This can take up to 25 seconds to complete.")
		i = 0
		while i < 60: 
			if self.getModemStatus():
				debug_print("modem still on")
				i += 1
			else:
				debug_print("modem powered down")
				return
		debug_print("power down timed out.  Modem may be stuck.")

	#******************************************************************************************
	#*** HAT Peripheral Functions *************************************************************
	#******************************************************************************************

	# Function for reading user button (active low)
	def readUserButton(self):
		return GPIO.input(self.USER_BUTTON_N)

	# Function for turning on user LED
	def turnOnUserLED(self):
		GPIO.output(self.USER_LED_N, 0)
	
	# Function for turning off user LED
	def turnOffUserLED(self):
		GPIO.output(self.USER_LED_N, 1)