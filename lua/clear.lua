-- O(N) of all the keys (scan)
-- +
-- O(N) where N is the number of items in queue
local name = KEYS[1];

local keys = redis.call('keys', name.."*")
for k, v in pairs(keys) do
  redis.call('del', v)
end

--local attrs = { "queued", "all", "retries", "timeout", "progress", "data", "priority", "failed", "failures", "completed", "pid", "host" }

--for k, v in pairs(attrs) do
  --redis.call('del', name..':'..v)
--end
