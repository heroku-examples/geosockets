ws = require('ws').Server
http = require 'http'
express = require 'express'
cookie = require 'cookie-cutter'
UserStore = require('./lib/user-store')

module.exports = ->

  # Abstracted Redis Store
  @users = new UserStore()

  # Express App (Static Frontend)
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

    # When a user established a connection, send them
    # a list of all connected users.
    #
    @users.getAll (err, users) ->
      return console.error(err) if err
      socket.send JSON.stringify(users)

    socket.on 'message', (data, flags) =>
      data = JSON.parse(data)
      return unless data

      # If an incoming message contains geodata, add it to redis
      # and notify all connected users.
      #
      if data and data.coords and data.coords.longitude
        @users.add data, (err, users) ->
          return console.error(err) if err
          @users.getAll (err, users) ->
            return console.error(err) if err
            for client in @socketServer.clients
              client.send JSON.stringify(users)

    socket.on "close", (code, message) =>

      # We could remove the user, but for now we'll just let
      # their entry in redis time out.

      # # Look in the socket cookie for UUID
      # uuid = cookie(socket.upgradeReq.headers.cookie).get('geosockets-uuid')

      # @users.remove uuid, (err, users) ->
      #   return console.error(err) if err

      #   # Send all users to all users!
      #   @users.getAll (err, users) ->
      #     return console.error(err) if err
      #     for client in @socketServer.clients
      #       client.send JSON.stringify(users)

  # Return app for testability
  @app