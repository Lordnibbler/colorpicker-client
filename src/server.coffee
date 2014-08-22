Http   = require 'http'
io     = require 'socket.io-client'
logger = require './logger'
FS     = require 'fs'

class Server
  buffer: []
  ws: undefined

  constructor: (@host, @port, @options = {}) ->

  #
  # connect to kernel and socket.io
  #
  run: (callback) ->
    @_setup_writestream()
    @_setup_sio()

  #
  # @return [String] URL based on config
  #
  _url: ->
    "http://#{ @host }#{ if @port? then ":#{@port}" else '' }/#{ @options.namespace }"

  #
  # connect socket.io client to url, bind to socket.io events and our custom events
  #
  _setup_sio: ->
    socket = new io(@_url(), {})
    socket.on 'connect', =>
      logger.info "connected to socket at #{@_url()}"

      # make an initial call to our recursive _write_pipe() method
      @_write_pipe()

    socket.on 'connect_error', (obj) => console.log 'connect error', obj
    socket.on 'disconnect',          => console.log "socket at #{@_url()} disconnected"
    socket.on 'colorChanged', (data) => @_to_buffer(data)
    socket.on 'colorSet',     (data) => @_to_buffer(data)

  #
  # create writestream to kernel at /dev/ttyO1
  #
  _setup_writestream: ->
    @ws = FS.createWriteStream "/dev/ttyO1",
      flags: "w+"

  #
  # if buffer has content, write buffer directly to the kernel via /dev/ttyO1 pipe
  # at 15ms resolution. recursively call this function using setInterval()
  #
  _write_pipe: ->
    setInterval (=>
      if @buffer.length > 0
        instruction = @buffer.shift()
        @ws.write(instruction)
    ), 1

  #
  # convert halo rgba string to a UART instruction and push to buffer, padding with black if needed
  # @example
  #   _data_to_buffer({ color: '000,110,255,000\n000,110,255,000\n' })
  #
  _to_buffer: (data) ->
    # break colors string into array, pop empty last value
    colors = data.color.split '\n'
    colors.pop()
    instruction_count = colors.length

    # build our TTY instruction
    @buffer.push("4,#{i+1},#{color};") for color, i in colors

    # pad with black if necessary
    @buffer.push("4,#{i+1},000,000,000,000;") for i in [instruction_count...5]

module.exports = Server
