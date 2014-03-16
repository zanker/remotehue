class BridgeSyncer
  include Sidekiq::Worker
  sidekiq_options :queue => :critical, :retry => true

  def perform
    Bridge.where(:status => Bridge::ACTIVE, :next_update_at.lte => Time.now.utc).each do |bridge|
      bridge.load_data
      bridge.manually_resynced = false
      bridge.save

      bridge.set(:next_update_at => 20.hours.from_now.utc + rand(4).hours)

      Stats.batch.increment("bridge.resync/#{bridge.valid? ? "success" : "error"}")
    end
  end
end