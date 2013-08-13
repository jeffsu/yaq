local name = KEYS[1]
local id   = KEYS[2]

redis.call('zrem', name..':queued', id)
redis.call('srem', name..':retries', id)
