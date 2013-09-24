http = require "http"
logfmt  = require 'logfmt'
errorLogger = new logfmt
errorLogger.stream = process.stderr

module.exports =

  getUserLocation: (req, res, next) ->
    ip = req.headers['x-forwarded-for']
    console.log "user ip is #{ip}"
    url = "http://freegeoip.net/json/#{ip}"

    http.get url, (rez) ->
      body = ""

      rez.on "data", (chunk) ->
        body += chunk

      rez.on "end", ->
        res.send JSON.parse(body)

      rez.on "error", (err) ->
        errorLogger.log err