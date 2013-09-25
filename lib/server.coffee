ws = require('ws').Server
http = require 'http'
express = require 'express'
# redis = require 'redis-client'

module.exports = ->

  # Express app
  @app = express()
  @app.configure =>
    @app.use @app.router
    @app.use '/', express.static('public')

  # HTTP listener
  @server = http.createServer(@app)
  @server.listen(process.env.PORT or 5000)

  @sockets = []
  # Websockets
  @socketServer = new ws(server: @server)
  @socketServer.on "connection", (socket) =>
    # socket.send "hello from the server"

    @sockets.push sockets
    console.log @sockets

    socket.on 'message', (position) =>
      # @positions.push(position)
      socket.send JSON.stringify(position)

      # TOOD: push location to database

      console.log "new position", position

    socket.on "close", (code, message) ->

      console.log "socket closed", code, message

      # socket.send "cloooooosed"
      # TODO: flush database

      # When a connection is closed, ask all remaining clients
      # to republish their location
      # socket.send JSON.stringify
      #   requestedAction: "publish"

  # Return app for testability
  @app