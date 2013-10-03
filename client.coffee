domready = require 'domready'
uuid = require 'node-uuid'
cookie = require 'cookie-cutter'
GeolocationStream = require 'geolocation-stream'

# mapbox auto-attaches to window.L (not cool)
# https://github.com/mapbox/mapbox.js/pull/498
require 'mapbox.js'

class GeoPublisher

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

class Map

  @defaultLatLng: [40, -74.50]
  @defaultZoom: 4

  constructor: ->

    @markers = []

    # Create a container DOM element for the map
    @el = document.createElement('div')
    @el.setAttribute('id', 'geosockets-map')
    document.querySelector('body').appendChild(@el)

    # Load CSS
    link = document.createElement("link")
    link.rel = "stylesheet"
    link.type = "text/css"
    link.href = "https://api.tiles.mapbox.com/mapbox.js/v1.3.1/mapbox.css"
    document.body.appendChild link

    # @map = L.mapbox.map('geosockets-map', 'financialtimes.map-w7l4lfi8')
    @map = L.mapbox.map('geosockets-map', 'examples.map-20v6611k')
      .setView([40, -74.50], 4)

  # Massage array of geodata into a GeoJSON-friendly format
  #
  toGeoJSON: (data) ->
    data.map (datum) ->
      datum = JSON.parse(datum)
      {
        type: "Feature"
        geometry:
          type: "Point"
          coordinates: [datum.coords.longitude, datum.coords.latitude]
        properties:
          title: "Someone"
          icon:
            iconUrl: "https://geosockets.herokuapp.com/marker.svg"
            iconSize: [10, 10]
            iconAnchor: [5, 5]
            popupAnchor: [0, -25] # point from which the popup should open relative to the iconAnchor
          # "marker-color": "#626AA3"
          # "marker-size": "small"
          # "marker-symbol": "marker"
      }

  render: (data) =>

    # Set a custom icon on each marker based on feature properties
    @map.markerLayer.on "layeradd", (e) ->
      marker = e.layer
      feature = marker.feature
      marker.setIcon L.icon(feature.properties.icon)

    @map.markerLayer.setGeoJSON(@toGeoJSON(data))

    # Pan the map to center this new marker
    # @map.panTo geodata.geometry.coordinates.reverse()

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
  window.geoPublisher = new GeoPublisher(socket)

  socket.onopen = (event) ->
    geoPublisher.publish()

  socket.onmessage = (event) ->
    data = JSON.parse(event.data)
    console.log data
    map.render(data) if data

  socket.onerror = (error) ->
    console.error error

  socket.onclose = (event) ->
    console.log 'socket closed', event