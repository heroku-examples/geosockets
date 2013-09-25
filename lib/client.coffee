domready = require('domready')
geolocationstream = require("geolocationstream")

    # if (!window['WebSocket']) {
    #     alert("No WebSocket support.");
    #     return;
    # }

class Geo

  constructor: (@socket) ->
    @position = null
    @stream = new geolocationstream()

    @stream.on "data", (position) =>
      @position = position
      @publish()

    @stream.on "error", (error) ->
      console.error error

  publish: ->
    if @socket.readyState is 1
      @socket.send JSON.stringify(@position)

domready ->

  # Open Socket
  host = location.origin.replace(/^http/, 'ws')
  window.socket = new WebSocket(host)
  window.geo = new Geo(socket)

  socket.onopen = (event) ->
    # socket.send 'greetings from client'
    geo.publish()

  socket.onmessage = (event) ->
    console.log JSON.parse(event.data)

    # switch event.data.requestedAction
    #   when 'publish' then geo.publish()

  socket.onerror = (error) ->
    console.error error