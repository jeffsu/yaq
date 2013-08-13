require 'coffee-script'
Queue = require './queue'

queues = {}
module.exports.create = (name, options={}) ->
  return queues[name] ||= new Queue(name, options)
