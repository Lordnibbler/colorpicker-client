Fs     = require 'fs'
Server = require './src/server'

loadServer = (host, port, options) ->
  new Server host, port, options

module.exports.loadServer = loadServer
