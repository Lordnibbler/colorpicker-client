#!/bin/sh -
sleep 10

# enable the UART1 in the device tree
echo BB-UART1 > /sys/devices/bone_capemgr.9/slots

# Set proper UART settings with STTY
stty -F /dev/ttyO1 speed 115200 ignbrk -brkint -icrnl -imaxbel -opost -onlcr -isig -icanon -iexten -echo -echoe -echok -echoctl -echoke noflsh -ixon -crtscts

# start the node client application
cd /home/root/colorpicker-beaglebone/
NODE_ENV=production npm start
