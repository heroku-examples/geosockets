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
    clickable: false
    keyboard: false
    weight: 2
    color: "#6762A6"
    opacity: 1
    fillColor: "#9674B7"
    fillOpacity: 1
    radius: 6
  userMarkerOptions:
    clickable: false
    keyboard: false
    weight: 2
    color: "#9674B7"
    opacity: 1
    fillColor: "#FFF"
    fillOpacity: 0.7
    radius: 14
    dashArray: "3, 6"

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
    @map.addControl(new L.Control.Fullscreen());

    # Accidentally scrolling with the trackpad sucks
    @map.scrollWheelZoom.disable()

    #
    @map.doubleClickZoom.disable()

  render: (newUsers) =>

    # Don't render if we've rendered recently
    if (Date.now()-@lastRenderedAt) < @maxRenderInterval
      log "rendered recently, skipping this round"
      return

    # Move the current user to the end of the array
    # so their marker z-index will be higher
    newUsers = newUsers.sort (a,b) ->
      a.uuid is cookie.get('geosockets-uuid')

    # Don't render more markers than the browser can handle
    # Take the users of the end of the array, so as to keep the newer
    # users and the current user.
    slice = if mobile() then @maxMarkersMobile else @maxMarkersDesktop
    newUsers = newUsers.slice -slice

    # Put every user on the map, even if they're already on it.
    newUsers = newUsers.map (user) =>
      user.marker = new L.AnimatedCircleMarker([user.latitude, user.longitude], @markerOptions)
      user.marker.addTo(@map)
      # user.marker2.addTo(@map) if user.marker2
      user

    # Now that all user markers are drawn,
    # remove the previously rendered batch of markers
    @users.map (user) =>
      user.marker.remove()
      # user.marker2.remove() if user.marker2

    # The number of SVG groups should equal to the number of users,
    # Keep an eye on it for performance reasons.
    log "marker count: ",
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
    @setRadius @options.radius
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