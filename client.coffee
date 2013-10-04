cookie = require 'cookie-cutter'
domready = require 'domready'
GeolocationStream = require 'geolocation-stream'
uuid = require 'node-uuid'
require 'mapbox.js' # auto-attaches to window.L

class GeoPublisher

  constructor: (@socket) ->
    @position = null
    @keepaliveInterval = 20*1000 # 20 seconds

    # Heroku closes the WebSocket connection after 55 seconds of
    # inactivity; keep it alive by republishing periodically
    setInterval (=>@publish()), @keepaliveInterval

    @stream = new GeolocationStream()
    @stream.on "data", (position) =>
      @position = position
      @position.uuid = cookie.get 'geosockets-uuid'
      @position.url = window.url
      @publish()

    @stream.on "error", (err) ->
      console.error err

  getLatLng: ->
    [@position.coords.latitude, @position.coords.longitude]

  publish: ->
    if @socket.readyState is 1
      @socket.send JSON.stringify(@position)

class Map

  constructor: ->
    @users = []
    @defaultLatLng = [40, -74.50]
    @defaultZoom = 4

    # Inject Mapbox CSS into the DOM
    link = document.createElement("link")
    link.rel = "stylesheet"
    link.type = "text/css"
    link.href = "https://api.tiles.mapbox.com/mapbox.js/v1.3.1/mapbox.css"
    document.body.appendChild link

    # Create the Mapbox map
    @map = L.mapbox
      .map('geosockets', 'examples.map-20v6611k') # 'financialtimes.map-w7l4lfi8'
      .setView(@defaultLatLng, @defaultZoom)

  render: (users) =>

    # Convert user location data into GeoJSON
    users = users.map (user) ->
      type: "Feature"
      geometry:
        type: "Point"
        coordinates: [user.coords.longitude, user.coords.latitude]
      properties:
        title: "Someone"
        icon:
          iconUrl: "https://geosockets.herokuapp.com/marker.svg"
          iconSize: [10, 10]
          iconAnchor: [5, 5]
          popupAnchor: [0, -10]

    # Set a custom icon on each marker
    @map.markerLayer.on "layeradd", (e) ->
      marker = e.layer
      feature = marker.feature
      marker.setIcon L.icon(feature.properties.icon)

    # Render the latest markers
    @map.markerLayer.setGeoJSON(users)

    # Pan to the user's location when the map is first rendered.
    @map.panTo(geoPublisher.getLatLng()) if @users.length is 0

    # Save the marker data for diffing the next time a broadcast is received.
    @users = users

domready ->

  unless window['WebSocket']
    alert "Your browser doesn't support WebSockets."
    return

  # Create a cookie that the server can use to uniquely identify each client.
  unless cookie.get 'geosockets-uuid'
    cookie.set 'geosockets-uuid', uuid.v4()

  # Determine the URL of the current page
  # Look first for a canonical URL, then default to window.location.href
  window.url = (document.querySelector('link[rel=canonical]') or window.location).href

  # Create the map
  window.map = new Map()

  # Open the socket connection
  # http://localhost:5000 -> ws://localhost:5000
  if location.host.match(/localhost/)
    host = location.origin.replace(/^http/, 'ws')
  else
    host = "ws://geosockets.herokuapp.com"
  window.socket = new WebSocket(host)

  # Start listening for browser geolocation events
  window.geoPublisher = new GeoPublisher(socket)

  socket.onopen = (event) ->
    geoPublisher.publish()

  socket.onmessage = (event) ->
    # Parse the JSON message array and each stringified JSON object within it
    users = JSON.parse(event.data).map(JSON.parse)
    return if !users or users.length is 0
    console.dir users
    map.render(users)

  socket.onerror = (error) ->
    console.error error

  socket.onclose = (event) ->
    console.log 'socket closed', event