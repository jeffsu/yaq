redis          = require 'redis'
{EventEmitter} = require 'events'

os     = require 'os'
code   = require './code'
Job    = require './job'

VALID_MESSAGES =
  queued:     true
  completed:  true
  retried:    true
  failed:     true
  timeout:    true
  processing: true

HOSTNAME = os.hostname()
PID      = process.pid

NOOP = ->


class Queue
  constructor: (@name, options) ->
    @retries = options.retries || 0

    @redis  = @createRedis(options)
    @pubsub = @createRedis(options)

    @redis.dbug_mode = true
    @redis.sadd 'yaq:queues', @name, NOOP

    @emitter = new EventEmitter
    @listened = {}

  createRedis: (options) ->
    if options.createRedis
      return options.createRedis()
    else
      return redis.createClient()

  counts: (cb) ->
    m = @redis.multi()

    m.zcard(@name + ':queued')
    m.zcard(@name + ':processing')
    m.zcard(@name + ':failed')
    m.zcard(@name + ':completed')

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
    message = arguments[0]
    @emitter.on.apply(@emitter, arguments)

    unless @listened[message]
      @listened[message] = true
      @pubsub.subscribe "#{@name}:#{message}", (data) =>
        @emit message, data

  emit: ->
    @emitter.emit.apply(@emitter, arguments)


module.exports = Queue
