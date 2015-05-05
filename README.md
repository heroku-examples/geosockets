# Geosockets

Geosockets is a Node.js webserver and javascript browser client for rendering website
visitors on a map in realtime using WebSockets and the browser's Geolocation API.

See the demo app at [geosockets.herokuapp.com](https://geosockets.herokuapp.com) and
the Heroku WebSocket Beta announcement at [blog.heroku.com/archives/2013/10/8/websockets-public-beta](https://blog.heroku.com/archives/2013/10/8/websockets-public-beta).

### The Client

[client.coffee](https://github.com/heroku-examples/geosockets/blob/master/client.coffee) is written as a node app that uses [Coffeeify](https://github.com/substack/coffeeify) (the red-headed step-child of [browserify](https://github.com/substack/node-browserify#readme)) and [Grunt](http://gruntjs.com/) to transpile the source into a single browser-ready javascript file.

When the client is first run in the browser, a [UUID](https://github.com/broofa/node-uuid#readme) token is generated and stored in a cookie which is passed to the server in the headers of each WebSocket message. This gives the server a consistent way to identify each user.

The client uses the [browser's geolocation API](https://www.google.com/search?q=browser%20geolocation%20api) and the [geolocation-stream](https://github.com/maxogden/geolocation-stream#readme) node module to determine the user's physical location, continually listening for location updates in realtime. Once the WebSocket connection is established, the client broadcasts its location to the server:

```js
{
  uuid: '6e381608-2e63-4e40-bf6c-31754935a5c2',
  url: 'https://blog.heroku.com/archives/2013/10/3/websockets-public-beta',
  latitude: 37.7521248,
  longitude: -122.42365649999999
}
```

The client then listens for messages from the server, rendering and removing markers from the map as site visitors come and go.

### The Server

[server.coffee](https://github.com/heroku-examples/geosockets/blob/master/server.coffee) is a node app powered by [express 3](http://expressjs.com/guide.html), node's native [http](http://nodejs.org/api/http.html) module, and the [einaros/ws](https://github.com/einaros/ws/blob/master/doc/ws.md) WebSocket implementation. Express is used to serve the static frontend in `/public`.

The server was designed with horizontal scalability in mind. The shared location dataset is stored in a redis datastore and each web dyno connects to this shared resource to pull the complete list of pins to place on the map. Clients viewing the map each establish their own WebSocket connection to any one of the backend web dynos and receive real-time updates as locations are added and removed from the redis datastore.

When the server receives a message from a client, it adds the client's location data to the Redis store (or updates if it's already present), using the combined client's URL/UUID pair as the Redis key:

```coffee
@redis.setex "#{user.url}---#{user.uuid}", @ttl, JSON.stringify(user)
```

The server then fetches all keys from Redis that match that URL and broadcasts the update
to all connected clients at that same URL.

### Embedding the Javascript Client on Your Site

The Geosockets JavasScript client can be used on any website:

```html
<link rel="stylesheet" type="text/css" href="https://geosockets.herokuapp.com/styles.css">
<script src="https://geosockets.herokuapp.com/client.js"></script>
<script>window.geosocket = new Geosocket("wss://geosockets.herokuapp.com");</script>
<div id="geosockets"></div>
```

Use CSS to configure the size and position of the map container:

```css
#geosockets {
  width: 100%;
  height: 100%;
}
```

### Running Geosockets Locally

If you're new to Heroku or Node.js development, you'll need to install a few things first:

1. [Heroku Toolbelt](https://toolbelt.heroku.com), which gives you git, foreman, and the heroku command-line interface.
1. [Node.js](http://nodejs.org/)
1. [Redis](http://redis.io/). If you're using [homebrew](http://brew.sh/), install with `brew install redis`

Clone the repo and install npm dependencies:

```sh
git clone https://github.com/heroku-examples/geosockets.git
cd geosockets
npm install
npm install -g grunt-cli
```

The foreman [Procfile](https://github.com/heroku-examples/geosockets/blob/master/Procfile) defines the processes
required to run the app. Fire up redis, a grunt watcher, and the node webserver at [localhost:5000/?debug](http://localhost:5000/?debug):

````
foreman start
```

### Debugging

The client uses a [custom logging function](https://github.com/heroku-examples/geosockets/blob/master/lib/logger.coffee)
that only logs messages to the console if a `debug` query param is present in the URL, e.g.
[localhost:5000/?debug](http://localhost:5000/?debug). This allows you to view client
behavior in production without exposing your site visitors to debugging data.

### Testing

Basic integration testing is done with [CasperJS](http://casperjs.org/), a navigation scripting & testing utility for [PhantomJS](http://phantomjs.org/). Casper is integrated into the app using the [grunt-casper](https://github.com/iamchrismiller/grunt-casper) plugin, and run with foreman. Each time you make a change to your client, the casper tests are run automatically.

### Deploying Geosockets to Heroku

```
heroku create my-geosockets-app
heroku labs:enable websockets
heroku addons:add openredis:micro # $10/month
git push heroku master
heroku open
```
