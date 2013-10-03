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
      data = JSON.parse(data)
      return unless data and data.coords

      @UserStore.add data, (err, users) ->
        return console.error(err) if err
        @UserStore.getByUrl data.url, (err, users) ->
          return console.error(err) if err
          for client in @socketServer.clients
            client.send JSON.stringify(users)


  # Return app for testability
  @app