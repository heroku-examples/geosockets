# geosocket

Display your site's current visitors on a map. A Heroku websockets demo app.

- geosockets.heroku.com
- github.com/zeke/geosockets

## Under the Hood

gesockets is a node app powered by [Express 3](http://expressjs.com/guide.html) and the [einaros/ws](https://github.com/einaros/ws/blob/master/doc/ws.md) WebSocket implementation. It has a static frontend in `/public`, served by Express. [Browserify](https://github.com/substack/node-browserify#readme) and [Grunt](http://gruntjs.com/) are used to compile the sites static frontend, found in `/public`.

geosockets is tested with [mocha](http://visionmedia.github.io/mocha/) and [supertest](https://github.com/visionmedia/supertest#readme). Supertest pairs nicely with Express, allowing the entire express app to be mounted for simple and clean webservice integration tests.

## Running the App Locally

First off, you'll need to install the [Heroku Toolbelt](https://toolbelt.heroku.com)
and [Node.js](http://nodejs.org/).

```
git clone https://github.com/zeke/geosockets.git
cd geosockets
npm install
foreman start web
```

Then open [localhost:5000](http://localhost:5000) in your browser.

## Testing

```
npm test
```

## Deployment to Heroku

```
heroku create
heroku labs:enable websockets
git push heroku master
heroku open
```