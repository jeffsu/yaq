redis          = require 'redis'
{EventEmitter} = require 'events'

os     = require 'os'
code   = require './code'
Job    = require './job'

HOSTNAME = os.hostname()
PID      = process.pid
ATTRS    = [ 'data', 'failures', 'progress' ]
NOOP = ->

###
Redis Data
name:all        sorted set
name:queued     sorted set
name:processing sorted set
name:failed     sorted set
name:completed  sorted set
name:data       hash

name:<id>:log list
###

class Queue
  constructor: (@name, options) ->
    @retries = options.retries || 0

    @redis   = redis.createClient()
    @pubsub  = redis.createClient()

    @redis.dbug_mode = true
    @redis.sadd 'yaq:queues', @name, NOOP

    @ee = new EventEmitter

  counts: (cb) ->
    m = @redis.multi()

    m.zcard(@name + ':queued')
    m.zcard(@name + ':processing')
    m.scard(@name + ':failed')
    m.scard(@name + ':completed')

    m.exec (err, results) ->
      return cb(err) if err
      cb err,
        queued:     results[0]
        processing: results[1]
        failed:     results[2]
        completed:  results[3]
    

  clean: (cb=NOOP) ->
    @redis.eval code.clean, 2, @name, Date.now(), cb

  # O(1)
  clear: (cb=NOOP) ->
    @redis.eval code.clear, 1, @name, cb
   
  # O(1)
  push: (options, cb=NOOP) ->
    job = new Job(@, options)

    @redis.eval code.push, 2, @name, job.toJSON(),  (err, res) ->
      return cb(err) if err
      cb(err, if res then job else false)

  # O(1)
  process: (cb) ->
    @redis.eval code.process, 4, @name, HOSTNAME, PID, Date.now(), (err, id) =>
      return cb(err) if err
      if id
        @find(id, cb)
      else
        cb(null, null)

  find: (id, cb) ->
    Job.find(@, id, cb)

  on: ->
    @ee.on.apply(@ee, arguments)


module.exports = Queue
