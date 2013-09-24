ws = require('ws').Server
http = require 'http'
express = require 'express'
geosockets  = require './geosockets'

module.exports = ->

  # Create Express app
  @app = express()
  @app.configure =>
    @app.use @app.router
    @app.use '/', express.static('public')

  # Websockets
  @server = http.createServer(@app)
  @server.listen 8080

  wss = new ws(server: @server)

  wss.on "connection", (ws) ->

    console.log "ws connection"

    ws.send "hello from the server"

    ws.on 'message', (data, flags) ->
      console.log "ws message", data

    ws.on "close", (code, message) ->
      console.log "ws closed", code, message

  # Routes
  @app.get '/api', geosockets.getUserLocation

  @app.listen(process.env.PORT or 5000)

  # Return app for testability testable
  @app