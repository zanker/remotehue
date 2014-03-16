class ScheduleRunner
  include Sidekiq::Worker
  sidekiq_options :queue => :high, :retry => 3

  def perform(user_id, schedule_id)
    start_at = Time.now.to_f

    schedule = Schedule.find(schedule_id)
    schedule.triggers.each do |trigger|
      trigger.run_with_log(TriggerHistory::SCHEDULE, :schedule_id => schedule._id)
    end

    Stats.batch.increment("scheduler.processed/success")
    ScheduleHistory.create(:schedule_id => schedule_id, :user_id => user_id, :results => ScheduleHistory::SUCCESS, :created_at => Time.now.utc, :runtime => (Time.now.to_f - start_at), :trigger_ids => schedule.trigger_ids)

  rescue Exception => e
    Stats.batch.increment("scheduler.processed/error")
    ScheduleHistory.create(:schedule_id => schedule_id, :user_id => user_id, :results => ScheduleHistory::ERROR, :error_code => ScheduleHistory::EXCEPTION_RETRY, :created_at => Time.now.utc)

    raise
  end

  def retries_exhausted(user_id, schedule_id)
    Stats.batch.increment("scheduler.processed/gave.up")
    ScheduleHistory.create(:schedule_id => schedule_id, :user_id => user_id, :results => ScheduleHistory::ERROR, :error_code => ScheduleHistory::EXCEPTION_LIMIT, :created_at => Time.now.utc)
  end
end

