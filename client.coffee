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

  unless window['WebSocket']
    alert "Your browser doesn't support WebSockets."
    return

  # Create a cookie that the server can use to uniquely
  # identify this client. The prefix makes redis batch
  # operations easier.
  #
  unless cookie.get 'geosockets-uuid'
    cookie.set 'geosockets-uuid', "user:" + uuid.v4()

  # Open the socket connection
  # This regex works with http and https URLs.
  #
  host = location.origin.replace(/^http/, 'ws')
  window.socket = new WebSocket(host)

  # Start listening for geolocation events from the browser.
  #
  window.geo = new Geo(socket)

  socket.onopen = (event) ->
    geo.publish()

  socket.onmessage = (event) ->
    console.log JSON.parse(event.data)

  socket.onerror = (error) ->
    console.error error

  socket.onclose = (event) ->
    console.log 'socket closed', event