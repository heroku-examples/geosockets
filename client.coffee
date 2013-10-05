# stream = require 'stream'
# util = require 'util'
window.cookie = require 'cookie-cutter'
domready = require 'domready'
GeolocationStream = require 'geolocation-stream'
uuid = require 'node-uuid'
require 'mapbox.js' # auto-attaches to window.L

# Custom Logger only produces console output if browser
# supports it and a `debug` query param is present
window.log = ->
  if window['console'] and location.search.match(/debug/)
    console.log.apply(console,arguments)

class GeoPublisher
  keepaliveInterval: 3*1000
  position:
    uuid: cookie.get 'geosockets-uuid'
    url: (document.querySelector('link[rel=canonical]') or window.location).href

  constructor: (@socket) ->
    @stream = GeolocationStream()

    @stream.on "data", (position) =>
      # Firefox doesn't know how to JSON.stringify the Coords
      # object, so just pull out the lat/lng pair
      @position.latitude = position.coords.latitude
      @position.longitude = position.coords.longitude
      @publish()

    @stream.on "error", (err) ->
      log err

    # Heroku closes the connection after 55 seconds of inactivity;
    setInterval (=>@publish()), @keepaliveInterval

  publish: =>
    # @emit('publish', @position)
    if @position.latitude and @socket.readyState is 1
      @socket.send JSON.stringify(@position)

class Map
  users: []
  defaultLatLng: [40, -74.50]
  defaultZoom: 4
  markerOptions:
    animate: true
    clickable: false
    keyboard: false
    opacity: 1
    radius: 5
    fillColor: "#6762A6"
    color: "#6762A6"
    weight: 2
    fillOpacity: 0.8

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

    # Attempt to center map using the Geolocation API
    @map.locate
      setView: true

    # Accidentally scrolling with the trackpad sucks
    @map.scrollWheelZoom.disable()

  render: (newUsers) =>

    # Put every current user on the map, even if they're already on it.
    newUsers = newUsers.map (user) =>
      user.marker = new L.CircleMarker([user.latitude, user.longitude], @markerOptions)
      user.marker.addTo(@map)
      user

    # Now that all current user markers are drawn,
    # remove the previously rendered batch of markers
    @users.map (user) =>
      @map.removeLayer(user.marker)

    # The number of SVG groups should equal the number of users,
    # Keep an eye on it for performance reasons.
    log "marker count: ",
      document.querySelectorAll('leaflet-container svg g').length

    # The new users will be old next time
    @users = newUsers

class Geosocket

  constructor: (@config={}) ->
    @config.host or= location.origin.replace(/^http/, 'ws')
    @config.domId or= "geosockets"

    domready =>

      # Sorry, old IE.
      unless window['WebSocket']
        alert "Your browser doesn't support WebSockets."
        return

      # Create a cookie that the server can use to uniquely identify each client.
      unless cookie.get 'geosockets-uuid'
        cookie.set 'geosockets-uuid', uuid.v4()

      # Create the map
      window.map = new Map(@config.domId)

      # Open the socket connection
      window.socket = new WebSocket(@config.host)

      socket.onopen = (event) ->
        # Start listening for browser geolocation events
        window.geoPublisher = new GeoPublisher(socket)

      # Parse the JSON message array and each stringified JSON object
      # within it, then render new users on the map
      socket.onmessage = (event) ->
        users = JSON.parse(event.data).map(JSON.parse)
        return if !users or users.length is 0
        log "users", users
        map.render(users)

      socket.onerror = (error) ->
        log error

      socket.onclose = (event) ->
        log 'socket closed', event

window.Geosocket = Geosocket