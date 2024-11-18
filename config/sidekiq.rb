require 'sidekiq'
require 'sidekiq-scheduler'

Sidekiq.configure_server do |config|
  config.redis = {
    url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0'),
    password: ENV.fetch('REDIS_PASSWORD', nil)
  }

  config.on(:startup) do
    Sidekiq.schedule = YAML.load_file(Rails.root.join('config/sidekiq_schedule.yml'))
    SidekiqScheduler::Scheduler.instance.reload_schedule!
  end

  config.default_worker_options = {
    retry: 3,
    backtrace: true
  }

  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
  end

  config.server_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Server
  end

  SidekiqUniqueJobs::Server.configure(config)
end

Sidekiq.configure_client do |config|
  config.redis = {
    url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0'),
    password: ENV.fetch('REDIS_PASSWORD', nil)
  }


  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
  end
end