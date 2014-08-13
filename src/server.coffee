Http   = require 'http'
io     = require 'socket.io-client'
logger = require './logger'
FS     = require 'fs'

class Server
  constructor: (@host, @port, @options = {}) ->

  #
  # @return [String] URL based on config
  #
  url: ->
    "http://#{ @host }#{ if @port? then ":#{@port}" else '' }/#{ @options.namespace }"

  #
  # connect socket.io client to url, bind to socket.io events and our custom events
  #
  run: (callback) ->
    logger.debug "Connecting to url #{@url()}"
    socket = new io(@url(), {})

    socket.on 'connect',             => console.log "connected to socket at #{@url()}"
    socket.on 'connect_error', (obj) => console.log 'connect error', obj
    socket.on 'disconnect',          => console.log "socket at #{@url()} disconnected"
    socket.on 'colorChanged',           @_write_colors_data_to_file
    socket.on 'colorSet',               @_write_colors_data_to_file

  #
  # write our preformatted backbone.js color data to colors.txt
  #
  _write_colors_data_to_file: (data) ->
    logger.debug JSON.stringify(data, null, 2)

    ws = FS.createWriteStream("#{__dirname}/../colors.txt", { flags: "w+" })
    ws.write(data.color, (err, written) ->
      throw err if err
      ws.end()
    )

module.exports = Server
