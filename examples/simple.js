var q   = require('../lib')
var foo = qute.queue('foo')

task.jobs.create(options)
task.jobs.consume('name', function (job, next) { 
  job.log("working on this")
  job.error("error")
  job.progress(200, 2000)
  job.finish("error")
  next()
});

foo.jobs.on 'complete', (job) ->

foo.jobs.stats (err, data) ->
