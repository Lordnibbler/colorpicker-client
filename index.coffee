Server = require './src/server'
config = require './src/config'

new Server(
  config.server.host,
  config.server.port,
  { namespace: config.server.namespace }
).run()
