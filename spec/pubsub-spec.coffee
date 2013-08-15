async = require 'async'
yaq   = require '../src'

queue = yaq.create('test-pubsub')

describe "Queue Pubsub", ->
  params = { data: {}, timeout: 10000, priority: 'med', retries: 1 }

  beforeEach (done) ->
    queue.clear(done)

  it "queues", (done) ->
    queue.on 'queued', (id) ->
      expect(id).toBeTruthy()
      done()

    setTimeout (-> queue.push(params)), 500

  it "completes", (done) ->
    queued = null

    queue.on 'completed', (id) ->
      expect(id).toBe(queued.id)
      done()

    push = ->
      queue.push params, (err, job) ->
        console.log err, job.id
        queued = job
        queue.process((err, job) -> job.finish())

    setTimeout push, 500
