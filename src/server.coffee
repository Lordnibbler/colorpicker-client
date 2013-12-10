Http   = require 'http'
Socket = require 'socket.io'
logger = require './logger'
FS     = require 'fs'

class Server
  constructor: (@host, @port, @options = {}) ->
    @url = "https://#{ @host }:#{ @port }/"

  close: (callback) ->
    @app.close(callback)

  run: (callback) ->
    @app = Http.createServer(@handler).listen(@port, @host, callback)
    @_sio_configure_listener(@app)

  handler: (req, res) ->
    res.writeHead 200
    res.end

  _sio_configure_listener: (app) ->
    _this = this
    sio = Socket.connect('http://127.0.0.1:1337')

    sio.on 'colorChangedBeagleBone', (data) ->
      console.log 'colorChangedBeagleBone emitted'
      console.log data

  _write_colors_data_to_file: (data) ->
    logger.debug JSON.stringify(data, null, 2)

    ws = FS.createWriteStream("#{__dirname}/../colors.txt", {
      flags: "w+"
    })
    ws.write(data.color, (err, written) ->
      if err
        throw err
      ws.end()
    )

module.exports = Server
