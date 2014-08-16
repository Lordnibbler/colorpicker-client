#!/bin/sh -
sleep 10
#systemctl restart connman.service

#python ping_test.py >/dev/null &

cd /home/root/halo_git/

./Halo_Master.pl > /dev/null & 

cd /home/root/colorpicker-beaglebone/

NODE_ENV=production npm start

