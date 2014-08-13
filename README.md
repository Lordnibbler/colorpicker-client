# colorpicker-beaglebone
A socket.io 1.0 client that connects to a [colorpicker-server](http://github.com/lordnibbler/colorpicker-server) socket.io server.  

Its main purpose is to write rgb color data to a colors.txt file for [halo](https://github.com/lordnibbler/halo) to read.

## Getting Started
You'll need a [colorpicker-server](http://github.com/lordnibbler/colorpicker-server) instance running before this client is useful:

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
