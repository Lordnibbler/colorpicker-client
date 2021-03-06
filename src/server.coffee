Http   = require 'http'
io     = require 'socket.io-client'
logger = require './logger'
FS     = require 'fs'

class Server
  buffer: []
  ws: undefined
  timer: undefined

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

    socket.on 'connect_error', (obj) => logger.info 'connect error', obj
    socket.on 'disconnect',          => @_disconnected()
    socket.on 'colorChanged', (data) => @_to_buffer(data)
    socket.on 'colorSet',     (data) => @_to_buffer(data)

  #
  # when a client disconnects, clear any timer in memory to avoid memory leak or multiple
  # messages being sent in the future!
  #
  _disconnected: ->
    logger.info "socket at #{@_url()} disconnected"
    clearTimeout(@timer) if @timer?

  #
  # create writestream to kernel at /dev/ttyO1
  #
  _setup_writestream: ->
    @ws = FS.createWriteStream (if process.env.NODE_ENV == 'production' then '/dev/ttyO1' else '/dev/null'),
      flags: "w+"

  #
  # write buffer directly to the kernel via /dev/ttyO1 pipe
  # if buffer has content, at 30ms resolution. recursively call this function on success
  #
  _write_pipe: ->
    @timer = setTimeout (=>
      # recurse
      if @buffer.length == 0
        @_write_pipe()
      else
        @ws.write(@buffer, (err, written) =>
          throw err if err
          @buffer = ''
          @_write_pipe()
        )
    ), 15

  #
  # convert array of rgb objects into a UART instruction for arduino to process and pipe to LEDs
  # @example
  #   _data_to_instruction(color: [{ r: 100, g: 50, b: 0 }, { r: 100, g: 50, b: 0 }, ...)
  #   # => '345,5,1,100,50,0;2,100,50,0,3,000,000,000,4,000,000,000,5,000,000,000;'
  #
  _data_to_instruction: (data) ->
    # build our TTY instruction
    instruction = '345,5,'
    instruction += "#{i+1},#{color.r},#{color.g},#{color.b};" for color, i in data.color

    # padding with black if necessary
    instruction_count = (instruction.match(/;/g)||[]).length
    instruction += "#{i+1},000,000,000;" for i in [instruction_count...5]
    return instruction

  #
  # write socket.io color data to buffer as UART instruction
  #
  _to_buffer: (data) ->
    @buffer = @_data_to_instruction(data)

module.exports = Server
