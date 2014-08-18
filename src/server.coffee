Http       = require 'http'
io         = require 'socket.io-client'
SerialPort = require('serialport').SerialPort
logger     = require './logger'
FS         = require 'fs'
serial_port = undefined

class Server
  constructor: (@host, @port, @options = {}) ->

  #
  # connect to tty and socket.io
  #
  run: (callback) ->
    # @_setup_sio()
    @_setup_serialport()

  #
  # @return [String] URL based on config
  #
  _url: ->
    "http://#{ @host }#{ if @port? then ":#{@port}" else '' }/#{ @options.namespace }"

  #
  # connect socket.io client to url, bind to socket.io events and our custom events
  #
  _setup_sio: ->
    logger.debug "Socket.io connecting to url #{@_url()}"
    socket = new io(@_url(), {})
    socket.on 'connect',             => console.log "connected to socket at #{@_url()}"
    socket.on 'connect_error', (obj) => console.log 'connect error', obj
    socket.on 'disconnect',          => console.log "socket at #{@_url()} disconnected"
    socket.on 'colorChanged',           @_write_colors_over_tty
    socket.on 'colorSet',               @_write_colors_over_tty

  #
  # connect to /dev/ttyO1, on success fire a call to _setup_sio()
  #
  _setup_serialport: ->
    tty = '/dev/ttyO1'
    logger.debug "Node serialport connecting to #{tty}"

    serial_port = new SerialPort(tty,
      baudrate: 115200
    )

    serial_port.on "open", =>
      console.log "Node serialport connected to #{tty}"

      @_setup_sio()

      serial_port.on 'data', (data) ->
        console.log 'data received: ' + data

  #
  # break our colors string into array, write each color to the appropriate address
  # @example data
  #   { color: '000,110,255,000\n000,110,255,000\n000,110,255,000\n000,110,255,000\n000,110,255,000\n' }
  #
  _write_colors_over_tty: (data) ->
    logger.debug '_write_colors_over_tty'

    # break colors string into array
    colors = data.color.split '\n'
    colors.pop()

    # build our TTY instruction, padding with black if necessary
    logger.debug "colors: #{colors} length: #{colors.length}"
    instruction = ''
    instruction += "4,#{i+1},#{color};" for color, i in colors

    instruction_count = (instruction.match(/;/g)||[]).length
    for i in [instruction_count...5]
      instruction += "4,#{i+1},000,000,000,000;"

    # write over TTY
    logger.debug "writing to serial port: #{instruction}"
    serial_port.write instruction

module.exports = Server
