uuid              = require 'node-uuid'
GeolocationStream = require 'geolocation-stream'

module.exports = class Geopublisher
  keepaliveInterval: 30*1000
  lastPublishedAt: 0
  position: {}

  constructor: (@socket) ->

    # Create a cookie that the server can use to uniquely identify each client.
    @position.uuid = cookie.get 'geosockets-uuid' or cookie.set('geosockets-uuid', uuid.v4())

    @position.url = (document.querySelector('link[rel=canonical]') or window.location).href

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
    # Don't publish if the socket is still connecting
    return if socket.readyState isnt 1

    # Don't publish if geodata isn't yet available.
    return if !@position.latitude

    # Don't publish too often
    return if (Date.now()-@lastPublishedAt) < @keepaliveInterval/2

    log "publish position:", @position
    @socket.send JSON.stringify(@position)
    @lastPublishedAt = Date.now()