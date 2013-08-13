-- O(1)
-- returns nil or list of values
local name = KEYS[1]
local id   = KEYS[2]

local json = redis.call('hget', name..':json', id)
if json then
  local status = nil
  if redis.call('zscore', name..':queued', id) then
    status = "queued"
  elseif redis.call('zscore', name..':processing', id) then
    status = "processing"
  elseif redis.call('zscore', name..':completed', id) then
    status = "completed"
  elseif redis.call('zscore', name..':failed', id) then
    status = "failed"
  end

  return {
    json,
    redis.call('hget', name..':progress', id),
    redis.call('hget', name..':host', id),
    redis.call('hget', name..':pid', id),
    redis.call('hget', name..':failures', id),
    status
  }
else
  return nil
end

