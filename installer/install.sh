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

# Bootstrapping ----------------------------------------------------------------
echo "${YELLOW}Preparing for installation${SET}"
sudo apt-get --assume-yes update
sudo apt-get --assume-yes upgrade
sudo apt-get --assume-yes install git python3-setuptools python3-pip python3-RPi.GPIO ppp 2>&1 | tee -a /home/pi/farmjenny/logs/install.log

# User input

echo "${YELLOW}Select the Farm Jenny hardware to install:${SET}"
echo "${YELLOW}1: LTE Border Router HAT${SET}"
echo "${YELLOW}2: Other${SET}"

read hardware
case $hardware in
    1)    echo "${YELLOW}You selected LTE Border Router HAT${SET}";;
    2)    echo "${YELLOW}You selected Other${SET}";;
    *)    echo "${RED}Sorry, I don't understand. Bye!${SET}"; exit 1;
esac

if [ $hardware -eq 1 ];	then

	echo "${YELLOW}What cellular modem is installed in the HAT?:${SET}"
	echo "${YELLOW}1: Nimbelink NL-SW-LTE-QBG96 (Quectel BG96)${SET}"
	echo "${YELLOW}2: Other modem${SET}"
	echo "${YELLOW}3: None${SET}"
	
	read modem
	case $modem in
		1)    echo "${YELLOW}You selected Nimbelink NL-SW-LTE-QBG96, configuring for LTE-M with 2G Fallback${SET}"
				EXTRA='';;
		2)    echo "${YELLOW}You selected Other modem, no extended settings to apply.${SET}"
				EXTRA='';;
		3)    echo "${YELLOW}You indicated no cellular modem installed, skipping modem config -- rerun this installer if a modem is added later.${SET}"
				EXTRA='';;
		*) 	  echo "${RED}Sorry, I don't understand. Bye!${SET}"; exit 1;
	esac
fi

if [ $hardware -eq 1 ];	then
	echo "${YELLOW}Daily automatic apt-get update/upgrades will consume significant cellular data.  May we disable them for you? [Y/n]${SET}"
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

		*)  echo "${RED}Please select one of: Y, y, N, or n${SET}";;
	esac
fi

if [ $hardware -eq 1 ];	then
	echo "${YELLOW}Installing Cellular Support${SET}"
	case $modem in
		1)    echo "${YELLOW}Installing Farm Jenny Libraries for HAT with BG96-based modem${SET}" 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
				git clone https://github.com/farmjenny/Farm_Jenny_Installer.git 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
				cd Farm_Jenny_Installer
				sudo python3 setup.py install 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
				;;
		2)    echo "${YELLOW}No libraries to install.${SET}";;
		3)    echo "${YELLOW}No libraries to install.${SET}";;
		*)    echo "${RED}Sorry, I don't understand. Bye!${SET}"; exit 1;
	esac
fi

if [ $hardware -eq 1 ];	then
	# Install the Farm Jenny gpio service to operate power, status, user led, etc. using legacy sysfs acccess.
	echo "${YELLOW}Configuring gpio pins at startup${SET}"
	wget --no-check-certificate  https://raw.githubusercontent.com/farmjenny/Farm_Jenny_Installer/master/installer/util/farmjenny_gpio.sh -O farmjenny_gpio.sh
	if [ $? -ne 0 ]; then
		echo "${RED}Download failed${SET}"
		exit 1;
	fi
	# copy file to correct location
	mkdir /usr/local/bin/farmjenny 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
	sudo mv farmjenny_gpio.sh /usr/local/bin/farmjenny/farmjenny_gpio.sh 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
	# make it executable
	sudo chmod +x /usr/local/bin/farmjenny/farmjenny_gpio.sh 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
	
	# add the farmjenny_gpio service
	wget --no-check-certificate  https://raw.githubusercontent.com/farmjenny/Farm_Jenny_Installer/master/installer/util/farmjenny_gpio.service -O farmjenny_gpio.service
	if [ $? -ne 0 ]; then
		echo "${RED}Download failed${SET}"
		exit 1;
	fi
	sudo mv farmjenny_gpio.service /lib/systemd/system/ 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
	sudo systemctl enable farmjenny_gpio.service 2>&1 | tee -a /home/pi/farmjenny/logs/install.log

	# Get the modem startup python utility
	wget --no-check-certificate  https://raw.githubusercontent.com/farmjenny/Farm_Jenny_Installer/master/installer/util/modem_on.py -O modem_on.py
	if [ $? -ne 0 ]; then
		echo "${RED}Download failed${SET}"
		exit 1;
	fi
	# copy file to correct location
	sudo mv modem_on.py /usr/local/bin/farmjenny/modem_on.py 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
	# make it executable
	sudo chmod +x /usr/local/bin/farmjenny/modem_on.py 2>&1 | tee -a /home/pi/farmjenny/logs/install.log

	# Install the Farm Jenny shutdown service to ensure a proper modem disconnect and shutdown (not doing so aggrevates the cell carriers).
	echo "${YELLOW}Installing Farm Jenny shutdown service for graceful cellular disconnect.${SET}"
	wget --no-check-certificate  https://raw.githubusercontent.com/farmjenny/Farm_Jenny_Installer/master/installer/util/farmjenny_shutdown.sh -O farmjenny_shutdown.sh
	if [ $? -ne 0 ]; then
		echo "${RED}Download failed${SET}"
		exit 1;
	fi
	# copy file to correct location
	sudo mv farmjenny_shutdown.sh /usr/local/bin/farmjenny/farmjenny_shutdown.sh 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
	# make it executable
	sudo chmod +x /usr/local/bin/farmjenny/farmjenny_shutdown.sh 2>&1 | tee -a /home/pi/farmjenny/logs/install.log

	# Get the modem shutdown python utility
	wget --no-check-certificate  https://raw.githubusercontent.com/farmjenny/Farm_Jenny_Installer/master/installer/util/modem_off.py -O modem_off.py
	if [ $? -ne 0 ]; then
		echo "${RED}Download failed${SET}"
		exit 1;
	fi
	# copy file to correct location
	sudo mv modem_off.py /usr/local/bin/farmjenny/modem_off.py 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
	# make it executable
	sudo chmod +x /usr/local/bin/farmjenny/modem_off.py	2>&1 | tee -a /home/pi/farmjenny/logs/install.log
	
	# add the farmjenny_shutdown service
	wget --no-check-certificate  https://raw.githubusercontent.com/farmjenny/Farm_Jenny_Installer/master/installer/util/farmjenny_shutdown.service -O farmjenny_shutdown.service
	if [ $? -ne 0 ]; then
		echo "${RED}Download failed${SET}"
		exit 1;
	fi
	sudo mv farmjenny_shutdown.service /lib/systemd/system/ 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
	sudo systemctl enable farmjenny_shutdown.service 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
fi

echo "${YELLOW}Downloading chatscript templates${SET}"
wget --no-check-certificate  https://raw.githubusercontent.com/farmjenny/Farm_Jenny_Installer/master/installer/ppp/chat-connect -O chat-connect

if [ $? -ne 0 ]; then
    echo "${RED}Download failed${SET}"
    exit 1; 
fi

wget --no-check-certificate  https://raw.githubusercontent.com/farmjenny/Farm_Jenny_Installer/master/installer/ppp/chat-disconnect -O chat-disconnect

if [ $? -ne 0 ]; then
    echo "${RED}Download failed${SET}"
    exit 1;
fi

wget --no-check-certificate  https://raw.githubusercontent.com/farmjenny/Farm_Jenny_Installer/master/installer/ppp/provider -O provider

if [ $? -ne 0 ]; then
    echo "${RED}Download failed${SET}"
    exit 1;
fi

echo "${YELLOW}What is your carrier's or MVNO's APN? (e.g., hologram)${SET}"
read carrierapn 

while [ 1 ]
do
	echo "${YELLOW}Does your carrier need username and password? [Y/n]${SET}"
	read usernpass
	
	case $usernpass in
		[Yy]* )  while [ 1 ] 
        do 
        
        echo "${YELLOW}Enter username${SET}"
        read username

        echo "${YELLOW}Enter password${SET}"
        read password
        sed -i "s/noauth/#noauth\nuser \"$username\"\npassword \"$password\"/" provider
        break 
        done

        break;;
		
		[Nn]* )  break;;
		*)  echo "${RED}Please select one of: Y, y, N, or n${SET}";;
	esac
done

echo "${YELLOW}What is your device communication PORT? (typ: ttyUSB3)${SET}"
read devicename

sudo rm -r /etc/chatscripts 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
sudo mkdir -p /etc/chatscripts 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
sed -i "/#EXTRA/d" chat-connect

mv chat-connect /etc/chatscripts/ 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
mv chat-disconnect /etc/chatscripts/ 2>&1 | tee -a /home/pi/farmjenny/logs/install.log

sudo rm -r /etc/ppp/peers 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
sudo mkdir -p /etc/ppp/peers 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
sed -i "s/#APN/$carrierapn/" provider
sed -i "s/#DEVICE/$devicename/" provider
mv provider /etc/ppp/peers/provider 2>&1 | tee -a /home/pi/farmjenny/logs/install.log

if ! (grep -q 'sudo route' /etc/ppp/ip-up ); then
    echo "sudo route del default" >> /etc/ppp/ip-up
    echo "sudo route add default ppp0" >> /etc/ppp/ip-up
fi

if [ $hardware -eq 1 ];	then
	echo "${YELLOW}Your HAT can operate as a Thread Border Router.  Install OTBR? (WARNING: this will take awhile) [Y/n]${SET}"
	read otbrinstall
	
	case $otbrinstall in
		[Yy]* )
        # Install OTBR
		echo "${YELLOW}Downloading OTBR${SET}"
        	sudo git clone  https://github.com/openthread/ot-br-posix.git 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
		cd ot-br-posix
		# check out a version ot OTBR we have tested
		git checkout ad26882 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
		
		# tell the build process we're using an RCP over SPI so it installs the interface
		echo "Adding RCP over SPI to OTBR_OPTIONS environment variable" 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
		OTBR_OPTIONS="-DOT_POSIX_CONFIG_RCP_BUS=SPI"
		# note that this export is limited in scope to this script
		export OTBR_OPTIONS
		printenv OTBR_OPTIONS 2>&1 | tee -a /home/pi/farmjenny/logs/install.log

		echo "${YELLOW}Installing OTBR dependencies${SET}"
		#source in the next line ensures the environment variable we just set is preserved
		# see:  https://stackoverflow.com/questions/8352851/how-to-call-one-shell-script-from-another-shell-script

		source ./script/bootstrap 2>&1 | tee -a /home/pi/farmjenny/logs/install.log

		echo "${YELLOW}Building OTBR${SET}"
		#source in the next line ensures the environment variable we just set is preserved
		source ./script/setup 2>&1 | tee -a /home/pi/farmjenny/logs/install.log

		echo "${YELLOW}Configuring OTBR to use the radio on the HAT${SET}"
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

		echo "${YELLOW}Finished installing OTBR.${SET}"
		cd ..

		;;
		[Nn]* )  break;;
		*)  echo "${RED}Please select one of: Y, y, N, or n${SET}";;
	esac
fi

echo "${YELLOW}Farm Jenny installation is complete.  Use ${BLUE}\"sudo pon\"${YELLOW} to connect and ${BLUE}\"sudo poff\"${YELLOW} to disconnect.${SET}" 
read -p "Press ENTER key to cleanup, reboot and start your device" ENTER
cd ${INSTALL_DIRECTORY}
sudo rm -r Farm_Jenny_Installer 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
sudo rm -r install.sh 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
echo "$(date) - Instal for Farm Jenny HAT finished." 2>&1 | tee -a /home/pi/farmjenny/logs/install.log
reboot