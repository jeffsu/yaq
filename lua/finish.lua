local name = KEYS[1]
local id   = KEYS[2]
local now  = KEYS[3]
local err  = KEYS[4]

-- check to see if exists, remove if does
if redis.call('zscore', name..':processing', id) then
  redis.call('zrem', name..':processing', id)
else
  return 0
end

-- errored, inc failed and possibly retry
if err then
  local retries = tonumber(redis.call('hget', name..':retries', id))
  redis.call('hincrby', name..':failures', id, 1)

  -- back on the queue
  if retries > 0 then
    local retries  = redis.call('hincrby', name..':retries', id, -1)
    local priority = redis.call('hget', name..':priority', id)
    redis.call('zadd', name..':queued', priority, id)
    redis.call('publish', name..':retried', id)

  -- put on failed list
  else
    redis.call('zadd', name..':failed', now, id)
    redis.call('publish', name..':failed', id)
  end

-- success
else

  redis.call('zadd', name..':completed', now, id)
  redis.call('publish', name..':completed', id)
end

return 1
