# geosockets

geosockets is a node webserver and javascript browser client for rendering
any site's visitors on a map in realtime using WebSockets.

See the demo app at [geosockets.heroku.com](https://geosockets.heroku.com).

### server.coffee

The server is a node app powered by [express 3](http://expressjs.com/guide.html), node's native [http](http://nodejs.org/api/http.html) module, and the [einaros/ws](https://github.com/einaros/ws/blob/master/doc/ws.md) WebSocket implementation. Express is used to serve the static frontend in `/public`.

> The twelve-factor app never assumes that anything cached in memory or on disk will be available on a future request or job.

Redis is used to persist visitor data. This allows the dynos running your app to act as [stateless processes](http://12factor.net/processes). In the context of Heroku, this means designing your app to withstand changes like restarting processes or scaling dynos up or down.

### client.coffee

[Browserify](https://github.com/substack/node-browserify#readme) and [Grunt](http://gruntjs.com/) are used to compile
server.coffee into a single browser-ready javascript file.

When the WebSocket connection is establised, the client determines the user's physical location using their [browser's geolocation API](https://www.google.com/search?q=browser%20geolocation%20api), then broadcasts its location to the server
over the WebSocket connection.

The client also listens for messages on the socket, rendering new visitors and removing departing visitors as the server
sends continuous updates.

### Running the App Locally

If you're new to Heroku or Node.js development, you'll need to install a few things first:

1. The [Heroku Toolbelt](https://toolbelt.heroku.com), which gives you git, foreman, and the heroku command-line interface.
1. [Node.js](http://nodejs.org/)
1. [redis](http://redis.io/)

Clone the repo and install npm dependencies:

```
git clone https://github.com/zeke/geosockets.git
cd geosockets
npm install
```

Fire up redis, a grunt watcher, and the node webserver at [localhost:5000](http://localhost:5000):

````
foreman start
```

### Testing

Geosockets is tested with [mocha](http://visionmedia.github.io/mocha/) and [supertest](https://github.com/visionmedia/supertest#readme). Supertest pairs nicely with Express, allowing the entire express app to be mounted for simple and clean webservice integration tests.

```
npm test
```

### Deploying to Heroku

```
heroku create my-geosockets-app
heroku labs:enable websockets
heroku addons:add openredis:micro # $10/month
git push heroku master
heroku open
```