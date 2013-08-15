redis          = require 'redis'
{EventEmitter} = require 'events'
async          = require 'async'

os      = require 'os'
code    = require './code'
Job     = require './job'

CHANNELS =
  queued:     true
  completed:  true
  retried:    true
  failed:     true
  timeout:    true
  processing: true

HOSTNAME = os.hostname()
PID      = process.pid

WATCH_INTERVAL = 5000

NOOP = ->


class Queue
  constructor: (@name, options) ->
    @retries = options.retries || 0

    @redis  = @createRedis(options)
    @pubsub = @createRedis(options)
    @pubsub.on 'message', (ch, data) => @handleMessage(ch, data)

    @redis.dbug_mode = true
    @redis.sadd 'yaq:queues', @name, NOOP

    @emitter  = new EventEmitter
    @listened = {}
    @toStop   = []

  createRedis: (options) ->
    if options.createRedis
      return options.createRedis()
    else
      return redis.createClient()

  # todo, pubsub to preempt
  watchProcess: (jobFn) ->
    if arguments[1]
      n     = arguments[0]
      jobFn = arguments[1]
    else
      n = 1

    running = true
    test    = -> running

    fn = (next) =>
      @process (err, job) ->
        if job
          job.once 'finish', next
          jobFn(job)
        else
          setTimeout(next, WATCH_INTERVAL)

    for i in [ 1 .. n ]
      async.whilst fn, test, NOOP

    @toStop.push -> running = false

  stop: ->
    fn() for fn in @toStop

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
  process: (cb=NOOP) ->
    @redis.eval code.process, 4, @name, HOSTNAME, PID, Date.now(), (err, id) =>
      return cb(err) if err
      if id
        @find(id, cb)
      else
        cb(null, null)

  find: (id, cb) ->
    Job.find(@, id, cb)

  handleMessage: (channel, data) ->
    console.log channel, data
    if m = channel.match(/^([^:]+):(.*)$/)
      @emit m[2], data

  on: ->
    message = arguments[0]
    @emitter.on.apply(@emitter, arguments)

    if CHANNELS[message] && !@listened[message]
      @listened[message] = true
      @pubsub.subscribe "#{@name}:#{message}"

  emit: ->
    @emitter.emit.apply(@emitter, arguments)


module.exports = Queue
