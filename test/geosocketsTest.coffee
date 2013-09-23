assert = require "assert"
geosockets = require "../lib/geosockets"

# suite "geosockets", ->

#   test "is an object", ->
#     assert.equal "object", typeof(geosockets)

#   test "locateUser", (done) ->
#     req =
#       headers:
#         'x-forwarded-for': '152.179.69.246'

#     res = {}
#     res.send = ->
#       console.log 'res.send()'

#     geosockets.locateUser (req, res, next) ->
#       assert error
#       assert.equal 'A valid uuid is required', error.message
#       done()