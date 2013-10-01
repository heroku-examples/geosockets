assert = require "assert"
supertest = require "supertest"
express = require "express"

server = require('server')()

suite "server", ->

  test "is a function", ->
    assert.equal "function", typeof(server)

  # describe "GET /api", ->

  #   test "matches city", (done) ->
  #     supertest(server).
  #       get("/api").
  #       set("Accept", "application/json").
  #       set("x-forwarded-for", '152.179.69.246').
  #       expect("Content-Type", /json/).
  #       expect(200).
  #       end (err, res) ->
  #         return done(err) if err
  #         assert res.body
  #         assert.equal res.body.city, "Ashburn"
  #         assert.equal res.body.region_name, "Virginia"
  #         done()