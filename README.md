# geosocket

Display your site's current visitors on a map. A Heroku websockets demo app.

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