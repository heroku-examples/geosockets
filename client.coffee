domready = require 'domready'
uuid = require 'node-uuid'
cookie = require 'cookie-cutter'
GeolocationStream = require 'geolocation-stream'

module.exports = class Geo

  constructor: (@socket) ->
    @position = null
    @stream = new GeolocationStream()

    @stream.on "data", (position) =>
      @position = position
      @position.uuid = cookie.get 'geosockets-uuid'
      @publish()

    @stream.on "error", (error) ->
      console.error error

  publish: ->
    if @socket.readyState is 1
      @socket.send JSON.stringify(@position)

window.exports = class Map

  constructor: ->
    @map = L.mapbox.map('map', 'examples.map-20v6611k')
      .setView([40, -74.50], 4)

  render: (data) ->
    for datum in data
      datum = JSON.parse(datum)
      geodata =
        type: "Feature"
        geometry:
          type: "Point"
          coordinates: [datum.coords.longitude, datum.coords.latitude]
        properties:
          "marker-color": "#626AA3"
          "marker-size": "small"
          # "marker-symbol": "marker"
          # For marker styling info, see
          # http://www.mapbox.com/developers/simplestyle/

      L.mapbox.markerLayer(geodata).addTo(@map)
      console.log geodata
      # console.log geodata.geometry.coordinates
      @map.panTo geodata.geometry.coordinates.reverse()

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

  # Create the map
  #
  window.map = new Map()

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
    data = JSON.parse(event.data)
    console.log data
    map.render(data) if data

  socket.onerror = (error) ->
    console.error error

  socket.onclose = (event) ->
    console.log 'socket closed', event