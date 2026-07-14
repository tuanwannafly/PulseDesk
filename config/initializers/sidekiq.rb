# Sidekiq adapter is loaded lazily; see config/application.rb.
# This file kept empty so existing config/initializer/* order doesn't break.
#
# To enable Sidekiq in production: install Redis, set REDIS_URL,
# uncomment below, and switch active_job.queue_adapter to :sidekiq.
#
# require 'sidekiq'
# require 'sidekiq/web'
#
# redis_url = ENV.fetch('REDIS_URL', 'redis://localhost:6379/0')
#
# Sidekiq.configure_server do |config|
#   config.redis = { url: redis_url }
# end
#
# Sidekiq.configure_client do |config|
#   config.redis = { url: redis_url }
# end
