# colorpicker-beaglebone
A socket.io 1.2 client that connects to a [colorpicker-server](http://github.com/lordnibbler/colorpicker-server) socket.io server.

Its main purpose is to convert an array of JSON RGB objects like `[{ r: 100, g: 50, b: 0 }, { r: 100, g: 50, b: 0 }` into a UART instruction like `'345,5,1,100,50,0;2,100,50,0,3,000,000,000,4,000,000,000,5,000,000,000;'`, and pipe it over UART to `/dev/ttyO1`.

## Getting Started
You'll need a [colorpicker-server](http://github.com/lordnibbler/colorpicker-server) instance running before this client is useful.  You can deploy this server to a free host like Heroku or Nodejitsu, or test locally.

```sh
# set up the GUI and server
git clone git@github.com:Lordnibbler/colorpicker-server.git
cd colorpicker-server
npm install -d
npm start

# set up the client
git clone git@github.com:Lordnibbler/colorpicker-beaglebone.git
cd colorpicker-beaglebone
npm install
npm start
```
You should see a `connected to socket at http://127.0.0.1:1337` message.

Browse to <http://localhost:1337> to use the GUI.

## Configuring a Beaglebone Black with Angstrom Distro
You'll need to do three things:

1. upgrade Node.js
2. configure `systemctl` to set up reliable network connectivity at boot
3. configure `systemctl` to start `colorpicker-beaglebone` Node service at boot

### 1. Upgrade Node.js
I refer you to the [wonderful instructions at speakinbytes.com](http://speakinbytes.com/2013/12/update-beaglebone-black-angstrom-node-js-version/). I recommend the current stable version of node, currently 0.10.32. You'll need at LEAST 0.10.0.

### 2. Network Connectivity
My findings have been that `connman` is very unreliable, so I fell back to using `/etc/network/interfaces`. To disable connman:

```sh
systemctl disable connman.service

# double check
systemctl status connman.service
```

Edit `/etc/network/interfaces` with your editor of choice. For ethernet/hardwired internet connectivity the only logic you need here is the loopback and the `eth0` configuration, but there's also some example wifi, USB, and bluetooth configs here:

```sh
# /etc/network/interfaces
# configuration file for ifup(8), ifdown(8)

# The loopback interface
auto lo
iface lo inet loopback

# Wireless interfaces
 iface wlan0 inet dhcp
	wireless_mode managed
	wireless_essid any
	wpa-driver wext
	wpa-conf /etc/wpa_supplicant.conf

 iface atml0 inet dhcp

# Wired or wireless interfaces
auto eth0
iface eth0 inet dhcp

# Ethernet/RNDIS gadget (g_ether)
# ... or on host side, usbnet and random hwaddr
iface usb0 inet static
	address 192.168.7.2
	netmask 255.255.255.0
	network 192.168.7.0
	gateway 192.168.7.1

# Bluetooth networking
iface bnep0 inet dhcp
```

If you want additional help setting up WiFi, [this article](http://octopusprotos.com/?p=37) is handy.

After setting up your interfaces, configure a `systemctl` service to start ethernet connectivity at boot, touch a new file located at `/etc/systemd/system/net.service`:

```sh
# /etc/systemd/system/net.service
[Unit]
Description=Network interfaces
Wants=network.target
Before=network.target
BindsTo=sys-subsystem-net-devices-eth0.device
After=sys-subsystem-net-devices-eth0.device

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/sh -c "sleep 5; ifup eth0"
ExecStop=/bin/sh -c "ifdown eth0"

[Install]
WantedBy=multi-user.target
```

Then enable the service!

```sh
systemctl enable net.service

# double check
systemctl start net.service
systemctl status net.service
```

You can check your connectivity using `ifconfig`.

### 3. Starting `colorpicker-beaglebone` at boot

To start this Beaglebone colorpicker client at boot, you can follow a similar approach to the network connectivity service.  I have provided an example in the `/angstrom` directory of this repository.

First, touch a new file at `/lib/systemd/system/colorpickerbeaglebone.service` (ensure your paths are correct, these are an example):

```sh
# /lib/systemd/system/colorpickerbeaglebone.service
[Unit]
Description=colorpicker-beaglebone automatic start

[Service]
WorkingDirectory=/home/root/colorpicker-beaglebone/angstrom
ExecStart=/home/root/colorpicker-beaglebone/angstrom/colorpickerbeaglebone.sh

[Install]
WantedBy=multi-user.target
```

You can copy the contents of `/angstrom/colorpickerbeaglebone.sh` from this repo if you intend to use UART + Arduino to power the LEDs.

Then enable the service!

```sh
systemctl enable colorpickerbeaglebone.service

# double check
systemctl start colorpickerbeaglebone.service
systemctl status colorpickerbeaglebone.service
```
