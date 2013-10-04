cookie = require 'cookie-cutter'
domready = require 'domready'
GeolocationStream = require 'geolocation-stream'
uuid = require 'node-uuid'
require 'mapbox.js' # auto-attaches to window.L

class GeoPublisher
  position: {}
  keepaliveInterval: 10*1000

  constructor: (@socket) ->
    @stream = new GeolocationStream()

    @stream.on "data", (position) =>

      # Firefox doesn't know how to JSON.stringify the coords
      # object, so just pull out the lat/lng pair
      @position.latitude = position.coords.latitude
      @position.longitude = position.coords.longitude
      @position.uuid = cookie.get 'geosockets-uuid'
      @position.url = window.url
      @publish()

    @stream.on "error", (err) ->
      console.error err

    # Heroku closes the WebSocket connection after 55 seconds of
    # inactivity; keep it alive by republishing periodically
    setInterval (=>@publish()), @keepaliveInterval

  isReady: =>
    @position.latitude and @socket.readyState is 1

  getLatLng: =>
    console.log "getLatLng", [@position.latitude, @position.longitude]
    [@position.latitude, @position.longitude]

  publish: =>
    @socket.send JSON.stringify(@position) if @isReady

class Map
  users: []
  markers: []
  defaultLatLng: [40, -74.50]
  defaultZoom: 4
  markerOptions:
    clickable: false
    keyboard: false
    opacity: 1
    icon: L.icon
      iconUrl: "https://geosockets.herokuapp.com/marker.svg"
      iconSize: [10, 10]
      iconAnchor: [5, 5]

  constructor: (@domId) ->

    # Remove '#' from DOM id, if present
    @domId = @domId.replace(/#/, '')

    # Inject Mapbox CSS into the DOM
    link = document.createElement("link")
    link.rel = "stylesheet"
    link.type = "text/css"
    link.href = "https://api.tiles.mapbox.com/mapbox.js/v1.3.1/mapbox.css"
    document.body.appendChild link

    # Create the Mapbox map
    @map = L.mapbox
      .map(@domId, 'examples.map-20v6611k') # 'financialtimes.map-w7l4lfi8'
      .setView(@defaultLatLng, @defaultZoom)

    @map.scrollWheelZoom.disable()

    @map.markers = L.mapbox.markerLayer()
      .addTo(@map)

  render: (users) =>

    # Who's already on the map?
    renderedUUIDs = @users.map (user) -> user.uuid

    # Pan to the user's location when the map is first rendered.
    if renderedUUIDs.length is 0 and geoPublisher.isReady
      @map.panTo(geoPublisher.getLatLng())

    for user in users
      # Skip this user if they're already on the map
      continue if user.uuid in renderedUUIDs

      # Add marker to map
      if user.latitude and user.longitude
        L.marker([user.latitude, user.longitude], @markerOptions)
          .addTo(@map.markers)

      # Add this user to list of already rendered users
      @users.push(user)

class Geosocket

  constructor: (@config={}) ->
    @config.host or= location.origin.replace(/^http/, 'ws')
    @config.domId or= "geosockets"

    domready =>

      unless window['WebSocket']
        alert "Your browser doesn't support WebSockets."
        return

      # Create a cookie that the server can use to uniquely identify each client.
      unless cookie.get 'geosockets-uuid'
        cookie.set 'geosockets-uuid', uuid.v4()

      # Determine the URL of the current page
      # Look for a canonical URL, then default to window.location.href
      window.url = (document.querySelector('link[rel=canonical]') or window.location).href

      # Create the map
      window.map = new Map(@config.domId)

      # Open the socket connection
      window.socket = new WebSocket(@config.host)

      socket.onopen = (event) ->
        # Start listening for browser geolocation events
        window.geoPublisher = new GeoPublisher(socket)

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

window.Geosocket = Geosocket