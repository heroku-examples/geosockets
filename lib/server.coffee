ws = require('ws').Server
http = require 'http'
express = require 'express'
redis = require 'redis'
cookie = require 'cookie-cutter'

module.exports = ->

  # Redis Pub/Sub
  redisUrl = require("url").parse(process.env.OPENREDIS_URL or 'redis://localhost:6379')
  @redis = redis.createClient(redisUrl.port, redisUrl.hostname)
  @subscriber = redis.createClient(redisUrl.port, redisUrl.hostname)
  @subscriber.on 'message', (channel, message) =>
    for socket in @socketServer.clients

      # Extend user expiration
      uuid = cookie(socket.upgradeReq.headers.cookie).get('geosockets-uuid')
      @redis.expire uuid, 60

      switch channel
        when "addUser"
          socket.send message
        when "removeUser"
          socket.send JSON.stringify "removeUser #{message}"

  @subscriber.subscribe 'addUser', 'removeUser'

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

    # Send all existing data to newly connected client
    @redis.keys 'user:*', (err, keys) ->
      return console.error(err) if err
      return if keys.length is 0
      @redis.mget keys, (err, geodata) ->
        socket.send JSON.stringify(geodata)

    # Handle incoming messages
    socket.on 'message', (data, flags) =>
      data = JSON.parse(data)
      return unless data

      # If message contains geodata, publish it.
      if data and data.coords and data.coords.longitude

        # Store the user's geodata in redis for a while
        @redis.setex data.uuid, 60, JSON.stringify(data)
        @redis.publish 'addUser', JSON.stringify(data)

    # Handle disappearing users
    socket.on "close", (code, message) =>
      # console.log "socket closed", code, message

      # Look in the socket cookie for UUID
      uuid = cookie(socket.upgradeReq.headers.cookie).get('geosockets-uuid')

      @redis.del uuid
      @redis.publish 'removeUser', uuid

  # Return app for testability
  @app