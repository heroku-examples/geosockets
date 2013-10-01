domready = require 'domready'
uuid = require 'node-uuid'
cookie = require 'cookie-cutter'
# Map = require __dirname + 'lib/map.coffee'

geolocationstream = require 'geolocationstream'

module.exports = class Geo

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

window.exports = class Map

  constructor: ->
    @map = L.mapbox.map('map', 'examples.map-20v6611k')
      .setView([40, -74.50], 9)

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
        # marker-size: one of small, medium or large. Can be used to put greater or lesser emphasis on a marker based on its size.
        # marker-color: a valid RGB hex color, like #ff4444. Color can be used to put emphasis on markers, group markers together by various colors, associate markers with various color semantics (e.g. green means good, red means bad) and more.
        # marker-symbol: an icon ID from the Maki project or a single alphanumeric character (a-z or 0-9). Attach a specific symbolic meaning to a marker.


      L.mapbox.markerLayer(geodata).addTo(@map)
      # console.log geodata
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
    map.render(data) if data

  socket.onerror = (error) ->
    console.error error

  socket.onclose = (event) ->
    console.log 'socket closed', event