express = require 'express'
http    = require 'http'
yaq     = require './index'
async   = require 'async'

app = express()
app.configure ->
  app.set('view engine', 'jade')
  app.set('views', __dirname + '/../views')
  app.use (req, res, next) ->
    if m = req.url.match(////q/([^/]+)///)
      res.locals.q = yaq.create(m[1])

    next()

  app.use(app.routes)

app.get "/q/:name/counts.json", (req, res, next) ->
  res.locals.q.counts (err, counts) ->
    return next(err) if err
    res.json(counts)

app.get "/q/:name", (req, res) ->
  q = yaq.create(req.params.name)
  res.render 'queue', { q: q }


server = http.createServer(app)

server.listen(5050)
