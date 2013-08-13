async = require 'async'
yaq   = require '../src'

describe "Queue Timing Out", ->
  queue = yaq.create('test')
  params = { data: {}, timeout: 1000, priority: 'med', retries: 1 }

  beforeEach (done) ->
    queue.clear (err) -> done()

  it 'times out after 1 second', (done) ->
    async.waterfall [
      (cb)      -> queue.push(params, cb)
      (job, cb) -> queue.process(cb)
      (job, cb) -> queue.process(cb)

      (job, cb) ->
        expect(job).toBeFalsy()
        setTimeout cb, 1002

      (cb)      -> queue.clean(cb)
      (res, cb) -> queue.process(cb)
    ], (err, job) ->
      expect(job).toBeTruthy()
      done()
    

