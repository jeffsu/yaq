uuid           = require 'uuid'
{EventEmitter} = require 'events'

code = require './code'

PRIORITIES =
  high: 10
  med:  50
  low:  100

LONGTIME = 1000 * 60 * 60 * 24
NOOP = ->

class Job extends EventEmitter
  constructor: (@q, options) ->
    # everything that is needed to wrap up to redis
    @me = {}

    @me.data     = options.data || {}
    @me.timeout  = parseInt(options.timeout || LONGTIME)
    @me.id       = options.id || uuid.v4()
    @me.priority = options.priority || 'med'
    @me.retries  = options.retries || 0

    @host = options.host
    @host = options.pid
    @failures = options.failures
    @status   = options.status

    @id = @me.id

  log: (msg, cb=NOOP) ->
    @q.redis.append("#{@q.name}:logs:#{@id}", "," + msg, cb)

  progress: (n, cb=NOOP) ->
    @q.redis.hset("#{@q.name}:progress", @id, n, cb)

  getLogs: (cb) ->
    @q.redis.get "#{@q.name}:logs:#{@id}", (err, str) ->
      return cb(err) if err
      cb(null, JSON.parse('[' + str.replace(/^,/, "") + ']'))

  getProgress: (cb) ->
    @q.redis.hget "#{@q.name}:progress", @id, (err, str) ->
      return cb(err) if err
      cb(null, parseFloat(str))

  toJSON: ->
    JSON.stringify(@me)

  finish: (err=null, cb=NOOP) ->
    @q.redis.eval code.finish, 4, @q.name, @id, Date.now(), err, (err, res) ->
      cb(err, res == 1)


Job.find = (q, id, cb) ->
  q.redis.eval code.find, 2, q.name, id, (err, results) ->
    return cb(err) if err || ! results

    [ data, progress, host, pid, failures, status ] = results

    options = JSON.parse(data)

    options.progress = parseFloat(progress)
    options.host     = host
    options.pid      = parseInt(pid)
    options.failures = parseInt(failures)
    options.status   = status

    cb(err, new Job(q, options))


    
module.exports = Job
