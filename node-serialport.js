// npm install node-serialport


var SerialPort = require("serialport").SerialPort;
var serialPort = new SerialPort("/dev/ttyO1", {
  baudrate: 115200
});

serialPort.on("open", function () {
  console.log('open');
  serialPort.on('data', function(data) {
    console.log('data received: ' + data);
  });
  serialPort.write('4,1,255,000,000,000;', function(err, results) {
    console.log('err ' + err);
    console.log('results ' + results);
  });
});
