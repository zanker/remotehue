class SecondaryTrigger
  include Sidekiq::Worker
  sidekiq_options :queue => :medium

  def perform(trigger_id)
    trigger = Trigger.where(:_id => trigger_id).first
    trigger.run_with_log(TriggerHistory::SECONDARY)
  end
end

