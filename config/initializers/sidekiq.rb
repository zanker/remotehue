Sidekiq.configure_server do |config|
  config.poll_interval = 10

  if Rails.env.production?
    config.redis = {:url => "redis://:1234@127.0.0.1"}
  end

  config.server_middleware do |chain|
    chain.add Sidekiq::Plugins::Librato
  end
end

Sidekiq.configure_client do |config|
  if Rails.env.production?
    config.redis = {:url => "redis://:1234@127.0.0.1"}
  end
end

# Hack a recurring scheduler into Sidekiq
if defined?(Sidekiq::CLI)
  Sidekiq.logger.info "Loaded rufus scheduler"

  scheduler = Rufus::Scheduler.start_new
  scheduler.every "5m" do
    SchedulerDispatch.perform_async
  end

  scheduler.every "30m" do
    BridgeSyncer.perform_async
  end

  scheduler.in "1s" do
    SchedulerDispatch.perform_async
    BridgeSyncer.perform_async
  end
end