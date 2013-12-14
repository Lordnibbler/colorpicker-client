Http   = require 'http'
io     = require 'socket.io-client'
logger = require './logger'
FS     = require 'fs'

class Server
  constructor: (@host, @port, @options = {}) ->
    @url = "http://#{ @host }:#{ @port }/beagleBone"

  close: (callback) ->
    io.disconnect

  run: (callback) ->
    socket = io.connect @url

    socket.on "connect", ->
      console.log "socket connected"

    # write our preformatted backbone.js
    # color data to colors.txt
    socket.on "colorChanged", @_write_colors_data_to_file
    socket.on "colorSet",     @_write_colors_data_to_file

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
