ws = require('ws').Server
http = require 'http'
express = require 'express'
cookie = require 'cookie-cutter'
UserStore = require('./lib/UserStore')

module.exports = ->

  # Abstracted Redis Store
  @userStore = new UserStore()

  # Express App
  @app = express()
  @app.configure =>
    @app.use @app.router
    @app.use '/', express.static('public')

  # HTTP Server
  @server = http.createServer(@app)
  @server.listen(process.env.PORT or 5000)

  # Websockets Server
  @socketServer = new ws(server: @server)
  @socketServer.on "connection", (socket) =>

    # Handle initial connection
    @userStore.getAll (err, users) ->
      return console.error(err) if err
      socket.send JSON.stringify(users)

    # Handle incoming messages
    socket.on 'message', (data, flags) =>
      data = JSON.parse(data)
      return unless data

      # If message contains geodata, publish it.
      if data and data.coords and data.coords.longitude

        @userStore.add data, (err, users) ->
          return console.error(err) if err

          # Send all users to all users!
          @userStore.getAll (err, users) ->
            return console.error(err) if err
            for socket in @socketServer.clients
              socket.send JSON.stringify(users)

    # Handle disappearing users
    socket.on "close", (code, message) =>
      # console.log "socket closed", code, message

      # Look in the socket cookie for UUID
      uuid = cookie(socket.upgradeReq.headers.cookie).get('geosockets-uuid')

      @userStore.remove uuid, (err, users) ->
        return console.error(err) if err

        # Send all users to all users!
        @userStore.getAll (err, users) ->
          return console.error(err) if err
          for socket in @socketServer.clients
            socket.send JSON.stringify(users)

  # Return app for testability
  @app