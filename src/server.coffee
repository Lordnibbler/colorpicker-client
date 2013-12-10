Http   = require 'http'
# socket = require 'socket.io-client'
io     = require 'socket.io-client'
logger = require './logger'
FS     = require 'fs'

class Server
  constructor: (@host, @port, @options = {}) ->
    @url = "https://#{ @host }:#{ @port }/"

  close: (callback) ->
    # @app.close(callback)

  run: (callback) ->
    socket = io.connect(@host,
      port: @port
    )
    socket.on "connect", ->
      console.log "socket connected"

    socket.on "colorChangedBeagleBone", (data) ->
      console.log colorChangedBeagleBone
      console.log data

    # socket.emit "private message",
    #   user: "me"
    #   msg: "whazzzup?"



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
