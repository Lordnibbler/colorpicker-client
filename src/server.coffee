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
  # write buffer directly to the kernel via /dev/ttyO1 pipe
  # if buffer has content, at 30ms resolution. recursively call this function on success
  #
  _write_pipe: ->
    setInterval (=>
      if @buffer.length > 0
        @ws.write(@buffer, (err, written) =>
          throw err if err
          # @ws.flush()
          @buffer = ''
        )
    ), 15

  #
  # convert halo rgba string to a UART instruction
  # @example
  #   _data_to_instruction({ color: '000,110,255,000\n255,000,000,000' })
  #   # => '345,5,1,255,000,000;2,255,000,000,3,000,000,000,4,000,000,000,5,000,000,000;'
  #
  _data_to_instruction: (data) ->
    # break colors string into array
    colors = data.color.split '\n'
    colors.pop()

    # remove `v` value from each color
    colors = colors.map (c) -> c.slice(0,-4)

    # build our TTY instruction
    instruction = '345,5,'
    instruction += "#{i+1},#{color};" for color, i in colors

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
