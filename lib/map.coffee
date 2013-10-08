merge = require 'merge'
# Mapbox auto-attaches to window.L when you require it.
# See https://github.com/mapbox/mapbox.js/pull/498
require 'mapbox.js'

module.exports = class Map
  domId: 'geosockets'
  tileSet: 'examples.map-20v6611k' # 'financialtimes.map-w7l4lfi8'
  lastRenderedAt: 0
  maxRenderInterval: 5*1000 # Don't render more than once every five seconds
  users: [] # Container array for geodata between renders
  defaultLatLng: [37.7720947, -122.4021025] # San Francisco
  defaultZoom: 11
  maxMarkersMobile: 50
  maxMarkersDesktop: 300
  markerOptions:
    animate: true
    clickable: false
    keyboard: false
    opacity: 1
    fillColor: "#6762A6"
    color: "#6762A6"
    weight: 2
    fillOpacity: 1

  constructor: () ->

    # Inject Mapbox CSS into the DOM
    link = document.createElement("link")
    link.rel = "stylesheet"
    link.type = "text/css"
    link.href = "https://api.tiles.mapbox.com/mapbox.js/v1.3.1/mapbox.css"
    document.body.appendChild link

    # Create the Mapbox map
    @map = L.mapbox
      .map(@domId, @tileSet)
      .setView(@defaultLatLng, @defaultZoom)
      .locate
        setView: true
        maxZoom: 11

    # Enable fullscreen option
    @map.addControl(new L.Control.FullScreen());

    # Accidentally scrolling with the trackpad sucks
    @map.scrollWheelZoom.disable()

  render: (newUsers) =>

    # Don't render if we've rendered recently
    if (Date.now()-@lastRenderedAt) < @maxRenderInterval
      log "rendered recently, skipping this round"
      return

    # Don't render too many markers on mobile devices
    if mobile()
      log "mobile device detected, capping markers at #{@maxMarkersMobile}"
      newUsers = newUsers.reverse().slice(0, @maxMarkersMobile)

    # Don't render too many markers on any device
    newUsers = newUsers.reverse().slice(0, @maxMarkersDesktop)

    # Put every current user on the map, even if they're already on it.
    newUsers = newUsers.map (user) =>
      # return user if user.uuid is cookie.get('geosockets-uuid')
      user.marker = new L.AnimatedCircleMarker([user.latitude, user.longitude], @markerOptions)
      user.marker.addTo(@map)
      user

    # Now that all current user markers are drawn,
    # remove the previously rendered batch of markers
    @users.map (user) =>
      user.marker.remove()

    # The number of SVG groups should equal the number of users,
    # Keep an eye on it for performance reasons.
    log "markers: ",
      document.querySelectorAll('.leaflet-container svg g').length

    # The new users will be the oldies next time around. Cycle of life, man.
    @users = newUsers

    # Keep track of the current time, so as not to render too often.
    @lastRenderedAt = Date.now()

# Extend Leaflet's CircleMarker and add radius animation
L.AnimatedCircleMarker = L.CircleMarker.extend
  options:
    interval: 20 #ms
    startRadius: 8
    endRadius: 8
    increment: 2

  initialize: (latlngs, options) ->
    L.CircleMarker::initialize.call @, latlngs, options

  onAdd: (map) ->
    L.CircleMarker::onAdd.call @, map
    @_map = map
    @setRadius @options.startRadius
    # @timer = setInterval (=>@grow()), @options.interval

  # grow: ->
  #   @setRadius @_radius + @options.increment
  #   if @_radius >= @options.endRadius
  #     clearInterval @timer

  remove: ->
    @_map.removeLayer(@)
    # @timer = setInterval (=>@shrink()), @options.interval

  # shrink: ->
  #   @setRadius @_radius - @options.increment
  #   if @_radius <= @options.startRadius
  #     clearInterval @timer
  #     @map.removeLayer(@)

L.animatedMarker = (latlngs, options) ->
  new L.AnimatedCircleMarker(latlngs, options)