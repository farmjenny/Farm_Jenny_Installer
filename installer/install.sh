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

echo "Downloading chatscript templates"
wget --no-check-certificate  https://raw.githubusercontent.com/farmjenny/Farm_Jenny_Installer/master/installer/chat-connect -O chat-connect

if [ $? -ne 0 ]; then
    echo "Download failed"
    exit 1; 
fi

wget --no-check-certificate  https://raw.githubusercontent.com/farmjenny/Farm_Jenny_Installer/master/installer/chat-disconnect -O chat-disconnect

if [ $? -ne 0 ]; then
    echo "Download failed"
    exit 1;
fi

wget --no-check-certificate  https://raw.githubusercontent.com/farmjenny/Farm_Jenny_Installer/master/installer/provider -O provider

if [ $? -ne 0 ]; then
    echo "Download failed"
    exit 1;
fi
echo "Installing PPP"
apt-get install ppp

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

read -p "Press ENTER key to reboot" ENTER
reboot