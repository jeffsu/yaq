async = require 'async'
yaq   = require '../src'

queue = yaq.create('test-pubsub')

describe "Pubsub'd Queue", ->
  params = { data: {}, timeout: 1000, priority: 'med', retries: 1 }

  beforeEach (done) ->
    queue.clear(done)

  it "emits queued", (done) ->
    queue.on 'queued', (id) ->
      expect(id).toBeTruthy()
      done()

    setTimeout (-> queue.push(params)), 500

  it "emits completed", (done) ->
    queued = null

    queue.on 'completed', (id) ->
      expect(id).toBe(queued.id)
      done()

    push = ->
      queue.push params, (err, job) ->
        queued = job
        queue.process((err, job) -> job.finish())

    setTimeout push, 500

  it "emits timeout", (done) ->
    queued = null

    queue.on 'timeout', (id) ->
      expect(id).toBe(queued.id)
      done()

    async.series [
      (cb) -> queue.push(params, cb)
      (cb) ->
        queue.process (err, job) ->
          queued = job
          cb()

      (cb) -> setTimeout cb, 1100
      (cb) -> queue.clean(cb)
    ], (err) ->
      expect(err).toBeFalsy()

  it "emits failed", (done) ->
    queue.on 'failed', (id) ->
      done()

    async.waterfall [
      (cb)      -> queue.push(params, cb)
      (job, cb) -> queue.process(cb)
      (job, cb) -> job.finish 'err', cb
      (cb)      -> queue.process(cb)
      (job, cb) -> job.finish 'err', cb
    ], (err) ->
      expect(err).toBeFalsy()


  it "emits retried, and processing", (done) ->
    queued     = null
    processing = false

    queue.on 'retried', (id) ->
      expect(id).toBe(queued.id)
      expect(processing).toBeTruthy()
      done()

    queue.on 'processing', (id) ->
      expect(id).toBe(queued.id)
      processing = true

    async.waterfall [
      (cb)      -> queue.push(params, cb)
      (job, cb) -> queued = job; queue.process(cb)
      (job, cb) -> job.finish('err', cb)
    ], (err) ->
      expect(err).toBeFalsy()
