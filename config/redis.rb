require 'redis'

REDIS_CONFIG = {
  url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0'),
  password: ENV.fetch('REDIS_PASSWORD', nil)
}.compact

Redis.current = Redis.new(REDIS_CONFIG)