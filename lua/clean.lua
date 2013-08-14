-- O(n) where n is the number of timed out jobs
-- +
-- O(n) where n is the number of failed jobs

local name = KEYS[1]
local now  = tonumber(KEYS[2])

-- check jobs that have been timed out
local timeout_ids = redis.call('zrangebyscore', name..':processing', 0, now)

for i, id in pairs(timeout_ids) do
  local retries = tonumber(redis.call('hget', name..':retries', id))

  if retries > 0 then
    local priority = redis.call('hget', name..':priority', id)
    redis.call('hincrby', name..':retries', id, -1)
    redis.call('zadd', name..':queued', priority, id)

    redis.call('publish', name..':timeout', id)
    redis.call('publish', name..':retried', id)
  else
    redis.call('zadd', name..':failed', now, id)
    redis.call('publish', name..':failed', id)
  end
end
