#!/bin/sh

YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[1;34m'
SET='\033[0m'

# Set up logging ---------------------------------------------------------------
mkdir -p /home/pi/farmjenny/logs
touch /home/pi/farmjenny/logs/install.log
echo "$(date) - Installing Farm Jenny HAT" 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
lsb_release -a 2>&1 | tee -a /home/pi/farmjenny/logs/install.log

INSTALL_DIRECTORY="$(pwd)"
MODEM_TYPE="NONE"

# Bootstrapping ----------------------------------------------------------------
echo "${YELLOW}Preparing for installation${SET}" 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
sudo apt-get --assume-yes --allow-releaseinfo-change update
sudo apt-get --assume-yes upgrade
sudo apt-get --assume-yes install git python3-setuptools python3-pip python3-RPi.GPIO ppp screen 2>&1 | tee -a /home/pi/farmjenny/logs/install.log

# Confirm git install was successful (Ref: BR-100)
git --version 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
if [ $? -ne 0 ]; then
    echo "${RED}Git Not Installed. Exiting..${SET}" 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
    exit 1;
fi

# User input

echo "${YELLOW}Select the Farm Jenny hardware to install:${SET}" 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
echo "${YELLOW}1: LTE Border Router HAT${SET}"
echo "${YELLOW}2: Other${SET}"

read hardware
case $hardware in
    1)    echo "${YELLOW}You selected LTE Border Router HAT${SET}" 2>&1 | tee -a /home/pi/farmjenny/logs/install.log;;
    2)    echo "${YELLOW}You selected Other${SET}";;
    *)    echo "${RED}Sorry, I don't understand. Bye!${SET}"; exit 1;
esac

if [ $hardware -eq 1 ];	then

	echo "${YELLOW}What cellular modem will be used with the HAT?:${SET}"
	echo "${YELLOW}1: Nimbelink NL-SW-LTE-QBG96 (Quectel BG96)${SET}"
	echo "${YELLOW}2: Nimbelink NL-SW-LTE-TC4NAG (Telit LE910C)${SET}"
	echo "${YELLOW}3: Nimbelink NL-SW-LTE-QBG95 or QBG95-B (Quectel BG95-M3)${SET}"
	echo "${YELLOW}9: None${SET}"
	
	read modem
	case $modem in
		1)    echo "${YELLOW}You selected Nimbelink NL-SW-LTE-QBG96, configuring for LTE-M with 2G Fallback${SET}" 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
				MODEM_TYPE="bg96"
				EXTRA='';;
		2)    echo "${YELLOW}You selected Nimbelink NL-SW-LTE-TC4NAG, no extended settings to apply.${SET}" 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
				MODEM_TYPE="le910c"
				EXTRA='';;
		3)    echo "${YELLOW}You selected Nimbelink NL-SW-LTE-QBG95, configuring for LTE-M with 2G Fallback${SET}" 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
				echo "${RED}WARNING: A driver for this modem may not be included in your linux distro. ${SET}" 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
				MODEM_TYPE="bg95"
				EXTRA='';;		
		9)    echo "${YELLOW}You indicated no cellular modem installed, skipping modem config -- rerun this installer if a modem is added later.${SET}" 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
				EXTRA='';;
		*) 	  echo "${RED}Sorry, I don't understand. Bye!${SET}" 2>&1 | tee -a /home/pi/farmjenny/logs/install.log; exit 1;
	esac
fi

if [ $hardware -eq 1 ];	then
	echo "${YELLOW}Daily automatic apt-get update/upgrades will consume significant cellular data.  May we disable them for you? [Y/n]${SET}" 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
	read disableapt
	
	case $disableapt in
		[Yy]* )
		# disable regular apt-get functionality    
        echo "${YELLOW}Disabling automatic apt-get activities.${SET}" 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
		# Stop running processes
		sudo systemctl stop apt-daily.timer 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
		sudo systemctl stop apt-daily-upgrade.timer 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
		# Prevent from restarting at boot
		sudo systemctl disable apt-daily.timer 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
		sudo systemctl disable apt-daily.service 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
		sudo systemctl disable apt-daily-upgrade.timer 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
		sudo systemctl daemon-reload 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
        
		;;

		[Nn]* )  
		echo "${RED}Automatic apt-get is still enabled.  Please monitor your cellular data use carefully to avoid nasty charges.${SET}" 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
		break;;

		*)  echo "${RED}Please select one of: Y, y, N, or n${SET}" 2>&1 | tee -a /home/pi/farmjenny/logs/install.log;;
	esac
fi

if [ $hardware -eq 1 ];	then
	echo "${YELLOW}Installing Cellular Support${SET}" 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
	case $modem in
		1)    echo "${YELLOW}Installing Farm Jenny Libraries for HAT with BG96-based modem${SET}" 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
				git clone https://github.com/farmjenny/Farm_Jenny_Installer.git 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
				cd Farm_Jenny_Installer
				sudo python3 setup.py install 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
				;;
		2)    echo "${YELLOW}Installing Farm Jenny Libraries for HAT with LE910C-based modem.${SET}" 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
				git clone https://github.com/farmjenny/Farm_Jenny_Installer.git 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
				cd Farm_Jenny_Installer
				sudo python3 setup.py install 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
				;;
		3)    echo "${YELLOW}Installing Farm Jenny Libraries for HAT with BG95-based modem${SET}" 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
				git clone https://github.com/farmjenny/Farm_Jenny_Installer.git 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
				cd Farm_Jenny_Installer
				sudo python3 setup.py install 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
				;;		
		9)    echo "${YELLOW}No libraries to install.${SET}" 2>&1 | tee -a /home/pi/farmjenny/logs/install.log;;
		*)    echo "${RED}Sorry, I don't understand. Bye!${SET}" 2>&1 | tee -a /home/pi/farmjenny/logs/install.log; exit 1;
	esac
fi

if [ $hardware -eq 1 ];	then
	# Install the Farm Jenny gpio service to operate power, status, user led, etc. using legacy sysfs acccess.
	echo "${YELLOW}Configuring gpio pins at startup${SET}" 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
	wget --no-check-certificate  https://raw.githubusercontent.com/farmjenny/Farm_Jenny_Installer/master/installer/util/farmjenny_gpio.sh -O farmjenny_gpio.sh
	if [ $? -ne 0 ]; then
		echo "${RED}Download failed${SET}" 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
		exit 1;
	fi
	# copy file to correct location
	sudo mkdir -p /usr/local/bin/farmjenny 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
	sudo mv farmjenny_gpio.sh /usr/local/bin/farmjenny/farmjenny_gpio.sh 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
	# make it executable
	sudo chmod +x /usr/local/bin/farmjenny/farmjenny_gpio.sh 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
	
	# add the farmjenny_gpio service
	wget --no-check-certificate  https://raw.githubusercontent.com/farmjenny/Farm_Jenny_Installer/master/installer/util/farmjenny_gpio.service -O farmjenny_gpio.service
	if [ $? -ne 0 ]; then
		echo "${RED}Download failed${SET}" 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
		exit 1;
	fi
	sudo mv farmjenny_gpio.service /lib/systemd/system/ 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
	sudo systemctl enable farmjenny_gpio.service 2>&1 | tee -a /home/pi/farmjenny/logs/install.log

	# Get the correct flavor of led blinking python utility (user_led_blink_ten.py)
	wget --no-check-certificate  https://raw.githubusercontent.com/farmjenny/Farm_Jenny_Installer/master/installer/util/common/user_led_blink_ten.py -O user_led_blink_ten.py
	if [ $? -ne 0 ]; then
		echo "${RED}Download failed${SET}" 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
		exit 1;
	fi
	# copy file to correct location
	sudo mv user_led_blink_ten.py /usr/local/bin/farmjenny/user_led_blink_ten.py 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
	# make it executable
	sudo chmod +x /usr/local/bin/farmjenny/user_led_blink_ten.py 2>&1 | tee -a /home/pi/farmjenny/logs/install.log

	# Get the correct flavor of user led ON python utility (user_led_on.py)
	wget --no-check-certificate  https://raw.githubusercontent.com/farmjenny/Farm_Jenny_Installer/master/installer/util/common/user_led_on.py -O user_led_on.py
	if [ $? -ne 0 ]; then
		echo "${RED}Download failed${SET}" 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
		exit 1;
	fi
	# copy file to correct location
	sudo mv user_led_on.py /usr/local/bin/farmjenny/user_led_on.py 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
	# make it executable
	sudo chmod +x /usr/local/bin/farmjenny/user_led_on.py 2>&1 | tee -a /home/pi/farmjenny/logs/install.log

	# Get the correct flavor of user led OFF python utility (user_led_off.py)
	wget --no-check-certificate  https://raw.githubusercontent.com/farmjenny/Farm_Jenny_Installer/master/installer/util/common/user_led_off.py -O user_led_off.py
	if [ $? -ne 0 ]; then
		echo "${RED}Download failed${SET}" 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
		exit 1;
	fi
	# copy file to correct location
	sudo mv user_led_off.py /usr/local/bin/farmjenny/user_led_off.py 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
	# make it executable
	sudo chmod +x /usr/local/bin/farmjenny/user_led_off.py 2>&1 | tee -a /home/pi/farmjenny/logs/install.log

	# Get the correct flavor of the button and led test routine (buttonledtest.py)
	wget --no-check-certificate  https://raw.githubusercontent.com/farmjenny/Farm_Jenny_Installer/master/installer/util/common/buttonledtest.py -O buttonledtest.py
	if [ $? -ne 0 ]; then
		echo "${RED}Download failed${SET}" 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
		exit 1;
	fi
	# copy file to correct location
	sudo mv buttonledtest.py /usr/local/bin/farmjenny/buttonledtest.py 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
	# make it executable
	sudo chmod +x /usr/local/bin/farmjenny/buttonledtest.py 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
fi

# MODEM-ONLY SETUP -- SKIP IF A MODEM ISN'T INSTALLED ....
if [ $hardware -eq 1 ] && [ $modem -ne 9 ];	then
	# Get the correct flavor of modem startup python utility
	wget --no-check-certificate  https://raw.githubusercontent.com/farmjenny/Farm_Jenny_Installer/master/installer/util/${MODEM_TYPE}/modem_on.py -O modem_on.py
	if [ $? -ne 0 ]; then
		echo "${RED}Download failed${SET}" 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
		exit 1;
	fi
	# copy file to correct location
	sudo mv modem_on.py /usr/local/bin/farmjenny/modem_on.py 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
	# make it executable
	sudo chmod +x /usr/local/bin/farmjenny/modem_on.py 2>&1 | tee -a /home/pi/farmjenny/logs/install.log

	# Install the Farm Jenny shutdown service to ensure a proper modem disconnect and shutdown (not doing so aggrevates the cell carriers).
	echo "${YELLOW}Installing Farm Jenny shutdown service for graceful cellular disconnect.${SET}" 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
	wget --no-check-certificate  https://raw.githubusercontent.com/farmjenny/Farm_Jenny_Installer/master/installer/util/farmjenny_shutdown.sh -O farmjenny_shutdown.sh
	if [ $? -ne 0 ]; then
		echo "${RED}Download failed${SET}"
		exit 1;
	fi
	# copy file to correct location
	sudo mv farmjenny_shutdown.sh /usr/local/bin/farmjenny/farmjenny_shutdown.sh 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
	# make it executable
	sudo chmod +x /usr/local/bin/farmjenny/farmjenny_shutdown.sh 2>&1 | tee -a /home/pi/farmjenny/logs/install.log

	# Get the correct flavor of modem shutdown python utility
	wget --no-check-certificate  https://raw.githubusercontent.com/farmjenny/Farm_Jenny_Installer/master/installer/util/${MODEM_TYPE}/modem_off.py -O modem_off.py
	if [ $? -ne 0 ]; then 
		echo "${RED}Download failed${SET}" 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
		exit 1;
	fi
	# copy file to correct location
	sudo mv modem_off.py /usr/local/bin/farmjenny/modem_off.py 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
	# make it executable
	sudo chmod +x /usr/local/bin/farmjenny/modem_off.py	2>&1 | tee -a /home/pi/farmjenny/logs/install.log
	
	# add the farmjenny_shutdown service
	wget --no-check-certificate  https://raw.githubusercontent.com/farmjenny/Farm_Jenny_Installer/master/installer/util/farmjenny_shutdown.service -O farmjenny_shutdown.service
	if [ $? -ne 0 ]; then
		echo "${RED}Download failed${SET}" 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
		exit 1;
	fi
	sudo mv farmjenny_shutdown.service /lib/systemd/system/ 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
	sudo systemctl enable farmjenny_shutdown.service 2>&1 | tee -a /home/pi/farmjenny/logs/install.log

	# Get the correct flavor of modem gnss_enable python utility
	wget --no-check-certificate  https://raw.githubusercontent.com/farmjenny/Farm_Jenny_Installer/master/installer/util/${MODEM_TYPE}/gnss_enable.py -O gnss_enable.py
	if [ $? -ne 0 ]; then
		echo "${RED}Download failed${SET}" 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
		exit 1;
	fi
	# copy file to correct location
	sudo mv gnss_enable.py /usr/local/bin/farmjenny/gnss_enable.py 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
	# make it executable
	sudo chmod +x /usr/local/bin/farmjenny/gnss_enable.py 2>&1 | tee -a /home/pi/farmjenny/logs/install.log

	# Get the correct flavor of modem gnss_query python utility
	wget --no-check-certificate  https://raw.githubusercontent.com/farmjenny/Farm_Jenny_Installer/master/installer/util/${MODEM_TYPE}/gnss_query.py -O gnss_query.py
	if [ $? -ne 0 ]; then
		echo "${RED}Download failed${SET}" 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
		exit 1;
	fi
	# copy file to correct location
	sudo mv gnss_query.py /usr/local/bin/farmjenny/gnss_query.py 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
	# make it executable
	sudo chmod +x /usr/local/bin/farmjenny/gnss_query.py 2>&1 | tee -a /home/pi/farmjenny/logs/install.log

	# Get the correct flavor of modem signal retrieval python utility (sig.py)
	wget --no-check-certificate  https://raw.githubusercontent.com/farmjenny/Farm_Jenny_Installer/master/installer/util/${MODEM_TYPE}/sig.py -O sig.py
	if [ $? -ne 0 ]; then
		echo "${RED}Download failed${SET}" 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
		exit 1;
	fi
	# copy file to correct location
	sudo mv sig.py /usr/local/bin/farmjenny/sig.py 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
	# make it executable
	sudo chmod +x /usr/local/bin/farmjenny/sig.py 2>&1 | tee -a /home/pi/farmjenny/logs/install.log

	# Get the correct flavor of modem operator retrieval python utility (opr.py)
	wget --no-check-certificate  https://raw.githubusercontent.com/farmjenny/Farm_Jenny_Installer/master/installer/util/${MODEM_TYPE}/opr.py -O opr.py
	if [ $? -ne 0 ]; then
		echo "${RED}Download failed${SET}" 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
		exit 1;
	fi
	# copy file to correct location
	sudo mv opr.py /usr/local/bin/farmjenny/opr.py 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
	# make it executable
	sudo chmod +x /usr/local/bin/farmjenny/opr.py 2>&1 | tee -a /home/pi/farmjenny/logs/install.log

	# Get the correct flavor of set modem default (set_modem_default.py)
	wget --no-check-certificate  https://raw.githubusercontent.com/farmjenny/Farm_Jenny_Installer/master/installer/util/${MODEM_TYPE}/set_modem_default.py -O set_modem_default.py
	if [ $? -ne 0 ]; then
		echo "${RED}Download failed${SET}" 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
		exit 1;
	fi
	# copy file to correct location
	sudo mv set_modem_default.py /usr/local/bin/farmjenny/set_modem_default.py 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
	# make it executable
	sudo chmod +x /usr/local/bin/farmjenny/set_modem_default.py 2>&1 | tee -a /home/pi/farmjenny/logs/install.log

	echo "${YELLOW}Downloading chatscript templates${SET}" 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
	wget --no-check-certificate  https://raw.githubusercontent.com/farmjenny/Farm_Jenny_Installer/master/installer/ppp/${MODEM_TYPE}/chat-connect -O chat-connect

	if [ $? -ne 0 ]; then
		echo "${RED}Download failed${SET}" 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
		exit 1; 
	fi

	wget --no-check-certificate  https://raw.githubusercontent.com/farmjenny/Farm_Jenny_Installer/master/installer/ppp/${MODEM_TYPE}/chat-disconnect -O chat-disconnect

	if [ $? -ne 0 ]; then
		echo "${RED}Download failed${SET}" 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
		exit 1;
	fi

	wget --no-check-certificate  https://raw.githubusercontent.com/farmjenny/Farm_Jenny_Installer/master/installer/ppp/${MODEM_TYPE}/provider -O provider

	if [ $? -ne 0 ]; then
		echo "${RED}Download failed${SET}" 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
		exit 1;
	fi

	echo "${YELLOW}What is your carrier's or MVNO's APN? (e.g., hologram)${SET}" 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
	read carrierapn 

	while [ 1 ]
	do
		echo "${YELLOW}Does your carrier need username and password? [Y/n]${SET}" 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
		read usernpass
		
		case $usernpass in
			[Yy]* )  while [ 1 ] 
			do 
			
			echo "${YELLOW}Enter username${SET}" 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
			read username

			echo "${YELLOW}Enter password${SET}" 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
			read password
			sed -i "s/noauth/#noauth\nuser \"$username\"\npassword \"$password\"/" provider
			break 
			done

			break;;
			
			[Nn]* )  break;;
			*)  echo "${RED}Please select one of: Y, y, N, or n${SET}" 2>&1 | tee -a /home/pi/farmjenny/logs/install.log;;
		esac
	done

	sudo rm -r /etc/chatscripts 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
	sudo mkdir -p /etc/chatscripts 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
	sed -i "/#EXTRA/d" chat-connect

	mv chat-connect /etc/chatscripts/ 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
	mv chat-disconnect /etc/chatscripts/ 2>&1 | tee -a /home/pi/farmjenny/logs/install.log

	sudo rm -r /etc/ppp/peers 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
	sudo mkdir -p /etc/ppp/peers 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
	sed -i "s/#APN/$carrierapn/" provider
	mv provider /etc/ppp/peers/provider 2>&1 | tee -a /home/pi/farmjenny/logs/install.log

	if ! (grep -q 'sudo route' /etc/ppp/ip-up ); then
		echo "sudo route del default" >> /etc/ppp/ip-up
		echo "sudo route add default ppp0" >> /etc/ppp/ip-up
	fi
fi

# END OF MODEM-ONLY CONFIG

if [ $hardware -eq 1 ];	then
	echo "${YELLOW}Your HAT can operate as a Thread Border Router.  Install OTBR? (WARNING: this will take awhile) [Y/n]${SET}" 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
	read otbrinstall
	
	case $otbrinstall in
		[Yy]* )
        # Install OTBR
		echo "${YELLOW}Downloading OTBR${SET}" 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
        	sudo git clone  https://github.com/openthread/ot-br-posix.git 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
		cd ot-br-posix
		# check out a version ot OTBR we have tested
		git checkout 8c73416 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
		
		echo "${YELLOW}Installing OTBR dependencies${SET}" 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
		sudo ./script/bootstrap 2>&1 | tee -a /home/pi/farmjenny/logs/install.log

		echo "${YELLOW}Building OTBR for SPI RCP Interface${SET}" 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
		sudo OTBR_OPTIONS="-DOT_POSIX_CONFIG_RCP_BUS=SPI" ./script/setup 2>&1 | tee -a /home/pi/farmjenny/logs/install.log

		echo "${YELLOW}Configuring OTBR to use the radio on the HAT${SET}" 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
		# replace the otbr-agent default settings with correct OTBR_AGENT_OPTS
		wget --no-check-certificate  https://raw.githubusercontent.com/farmjenny/Farm_Jenny_Installer/master/installer/util/otbr-agent-fj -O otbr-agent-fj
		if [ $? -ne 0 ]; then
    		echo "${RED}Download failed${SET}"
    		exit 1;
		fi
		# save a copy of the existing otbr-agent file
		sudo mv /etc/default/otbr-agent /etc/default/otbr-agent-default 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
		# insert the correct otbr-agent configuration file for the Farm Jenny HAT
		sudo mv otbr-agent-fj /etc/default/otbr-agent 2>&1 | tee -a /home/pi/farmjenny/logs/install.log

		echo "${YELLOW}Finished installing OTBR.${SET}" 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
		cd ..

		;;
		[Nn]* )  break;;
		*)  echo "${RED}Please select one of: Y, y, N, or n${SET}" 2>&1 | tee -a /home/pi/farmjenny/logs/install.log;;
	esac
fi

if [ $modem -eq 3 ];	then
	echo "${RED}WARNING:  You selected a Quectel BG95 modem - a suitable driver may not be included with your linux distro.${SET}"
	echo "${RED}With modem powered, if '>ls /dev/ttyUSB*' does not return multiple devices (e.g., ttyUSB0-ttyUSB4), you may need to install a driver.${SET}"
	echo "${RED}See https://github.com/farmjenny/FarmJenny_LTE_Border_Router_HAT/wiki/Quectel-BG95-Linux-Driver for more information.${SET}"
fi

echo "${YELLOW}Farm Jenny installation is complete.  If you installed a modem, use ${BLUE}\"sudo pon\"${YELLOW} to connect and ${BLUE}\"sudo poff\"${YELLOW} to disconnect.${SET}" 
read -p "Press ENTER key to cleanup, reboot and start your device" ENTER
cd ${INSTALL_DIRECTORY}
sudo rm -r Farm_Jenny_Installer 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
sudo rm -r install.sh 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
echo "$(date) - Install for Farm Jenny HAT finished." 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
reboot
