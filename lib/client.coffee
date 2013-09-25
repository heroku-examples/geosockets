domready = require 'domready'
geolocationstream = require 'geolocationstream'
uuid = require 'node-uuid'
cookie = require 'cookie-cutter'

class Geo

  constructor: (@socket) ->
    @position = null
    @stream = new geolocationstream()

    @stream.on "data", (position) =>
      @position = position
      @position.uuid = cookie.get 'geosockets-uuid'
      @publish()

    @stream.on "error", (error) ->
      console.error error

  publish: ->
    if @socket.readyState is 1
      @socket.send JSON.stringify(@position)

domready ->

  # Sorry, old IE...
  return unless window['WebSocket']

  # Create a uniquely identifying cookie
  unless cookie.get 'geosockets-uuid'
    cookie.set 'geosockets-uuid', "user:" + uuid.v4()

  # Open Socket
  host = location.origin.replace(/^http/, 'ws')
  window.socket = new WebSocket(host)

  # Fire up the Geostream!
  window.geo = new Geo(socket)

  socket.onopen = (event) ->
    geo.publish()

  socket.onmessage = (event) ->
    # console.log 'incoming message:', JSON.parse(event.data)
    console.log JSON.parse(event.data)

  socket.onerror = (error) ->
    console.error error

  socket.onclose = (event) ->
    console.log 'socket closed', event