http = require 'http'
redis = require 'redis'

module.exports = class UserStore

  constructor: (cb) ->
    @url = require("url").parse(process.env.OPENREDIS_URL or 'redis://localhost:6379')
    @redis = redis.createClient(@url.port, @url.hostname)
    @redis.auth(@url.auth.split(":")[1]) if @url.auth

    cb() if cb

  getAll: (cb) =>
    @redis.keys 'user:*', (err, keys) =>
      return cb(err) if err
      return cb(null, []) if keys.length is 0
      @redis.mget keys, (err, users) ->
        cb null, users

  add: (user, cb) =>
    @redis.setex user.uuid, 60, JSON.stringify(user)
    cb()

  remove: (uuid, cb) =>
    @redis.del uuid
    cb()