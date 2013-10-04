ws = require('ws').Server
http = require 'http'
express = require 'express'
cookie = require 'cookie-cutter'
UserStore = require('./lib/user-store')

module.exports = ->

  # Abstracted Redis Store
  @UserStore = new UserStore()

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
    socket.on 'message', (data, flags) =>
      user = JSON.parse(data)
      console.log user
      @UserStore.add user, (err, users) ->
        return console.error(err) if err
        @UserStore.getByUrl user.url, (err, users) ->
          return console.error(err) if err
          for client in @socketServer.clients
            client.send JSON.stringify(users)

  # Return app for testability
  @app