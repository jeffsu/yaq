-- O(1) pushes a job onto a queue
-- returns nil or true
local name  = KEYS[1]
local json  = KEYS[2]

local job = cjson.decode(json)

local PRIORITIES = { med=20, high=10, low=30 }

local priority = PRIORITIES[job.priority]
local timeout  = job.timeout
local id       = job.id

-- check if exists
if redis.call('zscore', name..':all', id) then
  return false

-- add to queue
else
  redis.call('zadd', name..':queued', priority, id)
  redis.call('sadd', name..':all', id)

  -- meta data
  redis.call('hset', name..':retries',  id, job.retries)
  redis.call('hset', name..':timeout',  id, job.timeout)
  redis.call('hset', name..':progress', id, job.progress)
  redis.call('hset', name..':json',     id, json)
  redis.call('hset', name..':priority', id, priority)

  redis.call('publish', name, 'queued:'..id)

  return true
end
