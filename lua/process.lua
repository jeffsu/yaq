-- O(1) pop job from queue
-- returns nil or json job data
local name = KEYS[1]
local host = KEYS[2]
local pid  = KEYS[3]
local now  = tonumber(KEYS[4])

-- get the top of the queue
local id = redis.call('zrange', name..':queued', 0, 0)[1]

-- found something
if id then
  local timeout  = tonumber(redis.call('hget', name..':timeout', id))
  local expireat = timeout + now

  -- set host/process metadata
  redis.call('hset', name..':pid', id, pid)
  redis.call('hset', name..':host', id, pid) 

  -- move to processing queue
  redis.call('zadd', name..':processing', expireat, id)
  redis.call('zrem', name..':queued', id)

  redis.call('publish', name, 'processing:'..id)

  return id

-- couldn't find anything
else
  return nil
end
