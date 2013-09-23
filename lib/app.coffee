express = require 'express'
logfmt  = require 'logfmt'
geosockets  = require './geosockets'

module.exports = ->

  @app = express()
  @app.configure =>
    @app.use logfmt.requestLogger()
    @app.use express.bodyParser()
    @app.use @app.router
    @app.use '/', express.static('public')

  @app.get '/api', geosockets.locateUser

  @app.get '/foo', (req, res, next) ->
    res.json('foo')

  @app.listen(process.env.PORT or 5000)

  @app