window.cookie    = require 'cookie-cutter'
window.uuid      = require 'node-uuid'
window.mobile    = require 'is-mobile'
domready         = require 'domready'
Geopublisher     = require './lib/geopublisher.coffee'
Map              = require './lib/map.coffee'
window.log       = require './lib/logger.coffee'

window.Geosocket = class Geosocket

  constructor: (@host) ->

    # If no WebSocket host is specified, derive it from the URL
    # http://example.com -> ws://example.com
    # https://example.com -> wss://example.com
    @host or= location.origin.replace(/^http/, 'ws')

    domready =>

      # Sorry, old IE.
      unless window['WebSocket']
        alert "Your browser doesn't support WebSockets."
        return

      unless cookie.get 'geosockets-uuid'
        cookie.set 'geosockets-uuid', uuid.v4()

      # Create the map
      window.map = new Map()

      # Open the socket connection
      window.socket = new WebSocket(@host)

      # Start listening for browser geolocation events
      socket.onopen = (event) ->
        window.geoPublisher = new Geopublisher(socket)

      # Parse the JSON message array and each stringified JSON object
      # within it, then render new users on the map
      socket.onmessage = (event) ->
        users = JSON.parse(event.data).map(JSON.parse)
        log "users", users
        map.render(users)

      socket.onerror = (error) ->
        log error

      socket.onclose = (event) ->
        log 'socket closed', event

    @

