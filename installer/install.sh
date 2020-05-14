#!/bin/sh

echo "Select the Farm Jenny hardware to install:"
echo "1: LTE Border Router HAT"
echo "2: Other"

read hardware
case $hardware in
    1)    echo "You selected LTE Border Router HAT";;
    2)    echo "You selected Other";;
    *)    echo "Sorry, I don't understand. Bye!"; exit 1;
esac

if [ $hardware -eq 1 ];	then
	echo "What cellular modem is installed in the HAT?:"
	echo "1: Nimbelink NL-SW-LTE-QBG96 (Quectel BG96)"
	echo "2: Other modem"
	echo "3: None"
	
	read modem
	case $modem in
		1)    echo "You selected Nimbelink NL-SW-LTE-QBG96, configuring for LTE-M with 2G Fallback"
				EXTRA='';;
		2)    echo "You selected Other modem, no extended settings to apply."
				EXTRA='';;
		3)    echo "You indicated no cellular modem installed, skipping modem config -- rerun this installer if a modem is added later."
				EXTRA='';;
		*) 	  echo "Sorry, I don't understand. Bye!"; exit 1;
	esac
fi

if [ $hardware -eq 1 ];	then
	echo "Installing Farm Jenny Libraries"
	case $modem in
		1)    echo "Installing Farm Jenny Libraries for HAT with BG96-based modem"
				git clone https://github.com/farmjenny/Farm_Jenny_Installer.git
				cd Farm_Jenny_Installer
				sudo python3 setup.py install
				;;
		2)    echo "No libraries to install.";;
		3)    echo "No libraries to install.";;
		*)    echo "Sorry, I don't understand. Bye!"; exit 1;
	esac
fi

echo "Downloading chatscript templates"
wget --no-check-certificate  https://raw.githubusercontent.com/farmjenny/Farm_Jenny_Installer/master/installer/ppp/chat-connect -O chat-connect

if [ $? -ne 0 ]; then
    echo "Download failed"
    exit 1; 
fi

wget --no-check-certificate  https://raw.githubusercontent.com/farmjenny/Farm_Jenny_Installer/master/installer/ppp/chat-disconnect -O chat-disconnect

if [ $? -ne 0 ]; then
    echo "Download failed"
    exit 1;
fi

wget --no-check-certificate  https://raw.githubusercontent.com/farmjenny/Farm_Jenny_Installer/master/installer/ppp/provider -O provider

if [ $? -ne 0 ]; then
    echo "Download failed"
    exit 1;
fi
echo "Installing PPP"
sudo apt-get --assume-yes install ppp

echo "What is your carrier's or MVNO's APN? (e.g., hologram)"
read carrierapn 

while [ 1 ]
do
	echo "Does your carrier need username and password? [Y/n]"
	read usernpass
	
	case $usernpass in
		[Yy]* )  while [ 1 ] 
        do 
        
        echo "Enter username"
        read username

        echo "Enter password"
        read password
        sed -i "s/noauth/#noauth\nuser \"$username\"\npassword \"$password\"/" provider
        break 
        done

        break;;
		
		[Nn]* )  break;;
		*)  echo "Please select one of: Y, y, N, or n";;
	esac
done

echo "What is your device communication PORT? (typically: ttyUSB3)"
read devicepath 

mkdir -p /etc/chatscripts
sed -i "/#EXTRA/d" chat-connect

mv chat-connect /etc/chatscripts/
mv chat-disconnect /etc/chatscripts/

mkdir -p /etc/ppp/peers
sed -i "s/#APN/$carrierapn/" provider
sed -i "s/#DEVICE/$devicepath/" provider
mv provider /etc/ppp/peers/provider

if ! (grep -q 'sudo route' /etc/ppp/ip-up ); then
    echo "sudo route del default" >> /etc/ppp/ip-up
    echo "sudo route add default ppp0" >> /etc/ppp/ip-up
fi

if [ $hardware -eq 1 ];	then
	echo "Your HAT can operate as a Thread Border Router.  Install OTBR? [Y/n]"
	read otbrinstall
	
	case $otbrinstall in
		[Yy]* )
        # Preparations
		echo "Installing git"
        sudo apt-get --assume-yes install git
		# Install OTBR
		echo "downloading OTBR"
        sudo git clone https://github.com/openthread/ot-br-posix
		cd ot-br-posix
		echo "installing OTBR dependencies"
		sudo ./script/bootstrap
		echo "Building OTBR without Access Point"
		sudo NETWORK_MANAGER=0 ./script/setup
		echo "Finished installing OTBR."
		cd ..
		# Install OpenThread Stack for RCP
		echo "Need OT Posix App for RCP"
		echo "downloading OT"
		sudo git clone https://github.com/openthread/openthread
		cd openthread
		sudo ./bootstrap
		sudo make -f src/posix/Makefile-posix clean
		sudo make -f src/posix/Makefile-posix
		# Move ot-ncp to proper location
		echo "moving ot-ncp to /usr/bin"
		sudo cp /output/posix/armv7l-unknown-linux-gnueabihf/bin/* /usr/bin/
		cd ..
		# Configure GPIO for INT and RESET at powerup (before wpantund starts)
		echo "Configuring gpio pins at startup"
		wget --no-check-certificate  https://raw.githubusercontent.com/farmjenny/Farm_Jenny_Installer/master/installer/util/farmjenny_gpio.sh -O farmjenny_gpio.sh
		if [ $? -ne 0 ]; then
    		echo "Download failed"
    		exit 1;
		fi
		# copy file to correct location
		sudo cp farmjenny_gpio.sh /home/pi/farmjenny_gpio.sh
		# make it executable

		# add the farmjenny_gpio service

		# edit the wpantund service to start after farmjenny_gpio

		# do something to update the dependencies / wants

		# install the service so it runs at startup

		# reconfigure wpantund for RCP
		echo "Configuring wpantund to use RCP with INT and RESET"
		wget --no-check-certificate  https://raw.githubusercontent.com/farmjenny/Farm_Jenny_Installer/master/installer/util/wpantund.conf.rcp -O wpantund.conf.rcp
		if [ $? -ne 0 ]; then
    		echo "Download failed"
    		exit 1;
		fi
		# save a copy of the existing wpantund configuration
		sudo mv /etc/wpantund.conf /etc/wpantund.conf.default
		# insert the correct wpantund configuration for rcp
		sudo cp wpantund.conf.rcp /etc/wpantund.config
				
		[Nn]* )  break;;
		*)  echo "Please select one of: Y, y, N, or n";;
	esac
fi

read -p "Farm Jenny installation is complete, press ENTER key to reboot and start your device" ENTER
reboot
