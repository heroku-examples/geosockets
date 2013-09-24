assert = require "assert"
request = require("supertest")
express = require("express")

app = require('../lib/app')()

suite "app", ->

  test "is a function", ->
    assert.equal "function", typeof(app)

  describe "GET /foo", ->
    it "responds with json", (done) ->
      request(app).
        get("/foo").
        set("Accept", "application/json").
        expect("Content-Type", /json/).
        expect 200, done

  describe "GET /api", ->
    test "matches city", (done) ->
      request(app).
        get("/api").
        set("Accept", "application/json").
        set("x-forwarded-for", '152.179.69.246').
        expect("Content-Type", /json/).
        expect(200).
        end (err, res) ->
          return done(err) if err
          assert res.body
          assert.equal res.body.city, "Ashburn"
          assert.equal res.body.region_name, "Virginia"
          done()