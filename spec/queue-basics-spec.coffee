async = require 'async'
yaq   = require '../src'

describe "Queue Basics", ->
  queue = yaq.create('test')
  params = { data: {}, timeout: 10000, priority: 'med', retries: 1 }
  
  beforeEach (done) ->
    queue.clear (err) -> done()

  it "pushes", (done)  ->
    async.waterfall [
      (cb)         -> queue.push(params, cb)
      (job, cb)    -> queue.find(job.id, cb)
    ], (err, job)  ->
      expect(job).toBeTruthy()
      done()

  it "processs", (done) ->
    async.waterfall [
      (cb)        -> queue.push(params, cb)
      (job, cb)   -> queue.process(cb)
    ], (err, job) ->
      expect(job).toBeTruthy()
      done()

  it "finishes with an error but gets pushed back on", (done) ->
    async.waterfall [
      (cb)         -> queue.push(params, cb)
      (job, cb)    -> queue.process(cb)
      (job, cb)    -> job.finish('error', cb)
      (passed, cb) -> queue.process(cb)
    ], (err, job) ->
      expect(job).toBeTruthy()
      done()

  it "only has 1 retry", (done) ->
    async.waterfall [
      (cb)         -> queue.push(params, cb)
      (job, cb)    -> queue.process(cb)
      (job, cb)    -> job.finish('error', cb)
      (passed, cb) -> queue.process(cb)
      (job, cb)    -> job.finish('error', cb)
      (passed, cb) -> queue.process(cb)
    ], (err, job) ->
      expect(job).toBeFalsy()
      done()
