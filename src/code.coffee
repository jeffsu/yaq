fs = require 'fs'

ROOT = __dirname + '/../lua'
code = (name) ->
  return fs.readFileSync("#{ROOT}/#{name}.lua").toString()

module.exports =
  push:    code('push')
  clear:   code('clear')
  process: code('process')
  find:    code('find')
  finish:  code('finish')
  clean:   code('clean')
