#!/bin/sh -
sleep 10
#systemctl restart connman.service

#enable the UART1 in the device tree
echo BB-UART1 > /sys/devices/bone_capemgr.9/slots


#Set proper UART settings with STTY

stty -F /dev/ttyO1 speed 115200 ignbrk -brkint -icrnl -imaxbel -opost
-onlcr -isig -icanon -iexten -echo -echoe -echok -echoctl -echoke noflsh
-ixon -crtscts

#python ping_test.py >/dev/null &

cd /home/root/halo_git/

#./Halo_Master.pl > /dev/null &

cd /home/root/colorpicker-beaglebone/

#NODE_ENV=production npm start

