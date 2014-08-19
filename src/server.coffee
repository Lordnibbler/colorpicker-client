Http   = require 'http'
io     = require 'socket.io-client'
logger = require './logger'
FS     = require 'fs'

class Server
  buffer: ''
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
    setImmediate (=>
      if @buffer.length == 0
        @_write_pipe()
      else
        ok = @ws.write @buffer
        if ok
          @buffer = ''
          @_write_pipe()
        else
          @ws.once('drain', =>
            @buffer = ''
            @_write_pipe
          )
    )

    # setImmediate(=>
    #   @ws.write(@buffer, (err, written) =>
    #     throw err if err
    #     @buffer = ''
    #   )
    # )

  #
  # convert halo rgba string to a UART instruction
  # @example
  #   _data_to_instruction({ color: '000,110,255,000\n' })
  #   # => '4,1,000,110,255,000;'
  #
  _data_to_instruction: (data) ->
    # break colors string into array, pop empty last value
    colors = data.color.split '\n'
    colors.pop()

    # build our TTY instruction
    instruction = ''
    instruction += "4,#{i+1},#{color};" for color, i in colors

    # padding with black if necessary
    instruction_count = (instruction.match(/;/g)||[]).length
    instruction += "4,#{i+1},000,000,000,000;" for i in [instruction_count...5]
    return instruction

  #
  # write socket.io color data to buffer as UART instruction
  #
  _to_buffer: (data) ->
    @buffer = @_data_to_instruction(data)
    @_write_pipe()

module.exports = Server
